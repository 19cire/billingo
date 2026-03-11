# app/services/zugferd_xml_generator.rb

class ZugferdXmlGenerator
  def initialize(invoice)
    @invoice = invoice
    @seller  = invoice.seller
    @buyer   = invoice.customer
  end

  def generate
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.send(
        "rsm:CrossIndustryInvoice",
        "xmlns:rsm" => "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100",
        "xmlns:ram" => "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100",
        "xmlns:udt" => "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"
      ) do
        # ── Dokumentkontext ─────────────────────────────────
        xml.send("rsm:ExchangedDocumentContext") do
          xml.send("ram:GuidelineSpecifiedDocumentContextParameter") do
            xml.send("ram:ID", zugferd_profile_urn)
          end
        end

        # ── Dokumentinformationen ───────────────────────────
        xml.send("rsm:ExchangedDocument") do
          xml.send("ram:ID", @invoice.number)
          xml.send("ram:TypeCode", @invoice.document_type || "380")
          xml.send("ram:IssueDateTime") do
            xml.send("udt:DateTimeString", @invoice.issue_date.strftime("%Y%m%d"), format: "102")
          end
        end

        # ── Transaktion ─────────────────────────────────────
        xml.send("rsm:SupplyChainTradeTransaction") do
          # ── Positionen ────────────────────────────────────
          @invoice.invoice_items.each_with_index do |item, index|
            xml.send("ram:IncludedSupplyChainTradeLineItem") do
              xml.send("ram:AssociatedDocumentLineDocument") do
                xml.send("ram:LineID", index + 1)
              end
              xml.send("ram:SpecifiedTradeProduct") do
                xml.send("ram:Name", item.description)
                xml.send("ram:Description", item.detail) if item.detail.present?
              end
              xml.send("ram:SpecifiedLineTradeAgreement") do
                xml.send("ram:NetPriceProductTradePrice") do
                  xml.send("ram:ChargeAmount", fmt(item.unit_price))
                end
              end
              xml.send("ram:SpecifiedLineTradeDelivery") do
                xml.send("ram:BilledQuantity", item.quantity, unitCode: item.unit_code || "C62")
              end
              xml.send("ram:SpecifiedLineTradeSettlement") do
                xml.send("ram:ApplicableTradeTax") do
                  xml.send("ram:TypeCode", "VAT")
                  xml.send("ram:CategoryCode", item.tax_category || "S")
                  xml.send("ram:RateApplicablePercent", item.tax_rate)
                end
                xml.send("ram:SpecifiedTradeSettlementLineMonetarySummation") do
                  xml.send("ram:LineTotalAmount", fmt(item.line_net_amount))
                end
              end
            end
          end

          # ── Handelsvereinbarung ───────────────────────────
          # Reihenfolge: Seller → Buyer → BuyerOrderReference
          xml.send("ram:ApplicableHeaderTradeAgreement") do
            # BT-10 Buyer Reference (optional)
            xml.send("ram:BuyerReference", @buyer.buyer_reference) if @buyer.buyer_reference.present?

            # Seller (BG-4)
            xml.send("ram:SellerTradeParty") do
              # BT-29 Seller identifier — Steuernummer als ID
              if @seller.tax_id.present?
                xml.send("ram:ID", @seller.tax_id)
              end
              xml.send("ram:Name", @seller.name)
              xml.send("ram:PostalTradeAddress") do
                xml.send("ram:PostcodeCode", @seller.postal_code)
                xml.send("ram:LineOne", @seller.street)
                xml.send("ram:CityName", @seller.city)
                xml.send("ram:CountryID", @seller.country_code)
              end
              # BT-31 VAT ID (mit ISO-Prefix z.B. DE123456789)
              if @seller.vat_id.present?
                xml.send("ram:SpecifiedTaxRegistration") do
                  xml.send("ram:ID", @seller.vat_id, schemeID: "VA")
                end
              end
              # BT-32 Steuernummer (FC = Fiscal Code)
              if @seller.tax_id.present?
                xml.send("ram:SpecifiedTaxRegistration") do
                  xml.send("ram:ID", @seller.tax_id, schemeID: "FC")
                end
              end
            end

            # Buyer (BG-7)
            xml.send("ram:BuyerTradeParty") do
              xml.send("ram:Name", @buyer.name)
              xml.send("ram:PostalTradeAddress") do
                xml.send("ram:PostcodeCode", @buyer.postal_code)
                xml.send("ram:LineOne", @buyer.street)
                xml.send("ram:CityName", @buyer.city)
                xml.send("ram:CountryID", @buyer.country_code)
              end
              if @buyer.vat_id.present?
                xml.send("ram:SpecifiedTaxRegistration") do
                  xml.send("ram:ID", @buyer.vat_id, schemeID: "VA")
                end
              end
            end

            # BT-13 Bestellnummer — NACH BuyerTradeParty
            if @invoice.order_reference.present?
              xml.send("ram:BuyerOrderReferencedDocument") do
                xml.send("ram:IssuerAssignedID", @invoice.order_reference)
              end
            end
          end

          # ── Lieferung ─────────────────────────────────────

          xml.send("ram:ApplicableHeaderTradeDelivery") do
            if @invoice.delivery_date.present?
              xml.send("ram:BillingSpecifiedPeriod") do
                xml.send("ram:StartDateTime") do
                  xml.send("udt:DateTimeString", @invoice.delivery_date.strftime("%Y%m%d"), format: "102")
                end
                if @invoice.service_period_end.present?
                  xml.send("ram:EndDateTime") do
                    xml.send("udt:DateTimeString", @invoice.service_period_end.strftime("%Y%m%d"), format: "102")
                  end
                end
              end
            end
          end

          # ── Zahlungsabwicklung ────────────────────────────
          xml.send("ram:ApplicableHeaderTradeSettlement") do
            xml.send("ram:InvoiceCurrencyCode", @invoice.currency_code || "EUR")

            # BG-16 Zahlungsmittel — VOR ApplicableTradeTax
            if @seller.iban.present?
              xml.send("ram:SpecifiedTradeSettlementPaymentMeans") do
                xml.send("ram:TypeCode", @invoice.payment_means_code || "58")
                xml.send("ram:PayeePartyCreditorFinancialAccount") do
                  xml.send("ram:IBANID", @seller.iban)
                end
                if @seller.bic.present?
                  xml.send("ram:PayeeSpecifiedCreditorFinancialInstitution") do
                    xml.send("ram:BICID", @seller.bic)
                  end
                end
              end
            end

            # BG-23 Steuer
            xml.send("ram:ApplicableTradeTax") do
              xml.send("ram:CalculatedAmount", fmt(@invoice.tax_amount))
              xml.send("ram:TypeCode", "VAT")
              xml.send("ram:BasisAmount", fmt(@invoice.net_amount))
              xml.send("ram:CategoryCode", @invoice.tax_category || "S")
              xml.send("ram:RateApplicablePercent", @invoice.tax_rate)
            end

            # Zahlungsbedingungen
            if @invoice.due_date.present?
              xml.send("ram:SpecifiedTradePaymentTerms") do
                xml.send("ram:Description", @invoice.payment_terms) if @invoice.payment_terms.present?
                xml.send("ram:DueDateDateTime") do
                  xml.send("udt:DateTimeString", @invoice.due_date.strftime("%Y%m%d"), format: "102")
                end
              end
            end

            # Gesamtbeträge
            xml.send("ram:SpecifiedTradeSettlementHeaderMonetarySummation") do
              xml.send("ram:LineTotalAmount",     fmt(@invoice.net_amount))
              xml.send("ram:TaxBasisTotalAmount",  fmt(@invoice.net_amount))
              xml.send("ram:TaxTotalAmount",       fmt(@invoice.tax_amount), currencyID: @invoice.currency_code || "EUR")
              xml.send("ram:GrandTotalAmount",     fmt(@invoice.gross_amount))
              xml.send("ram:DuePayableAmount",     fmt(@invoice.gross_amount))
            end
          end
        end
      end
    end

    builder.to_xml
  end

  private

  def fmt(amount)
    "%.2f" % amount.to_f
  end

  def zugferd_profile_urn
    profiles = {
      "MINIMUM"  => "urn:factur-x.eu:1p0:minimum",
      "BASIC_WL" => "urn:factur-x.eu:1p0:basicwl",
      "BASIC"    => "urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic",
      "EN_16931" => "urn:cen.eu:en16931:2017",
      "EXTENDED" => "urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended"
    }
    profiles[@invoice.zugferd_profile || "EN_16931"]
  end
end
