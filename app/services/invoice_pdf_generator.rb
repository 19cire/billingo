
class InvoicePdfGenerator
  def initialize(invoice)
    @invoice = invoice
    @seller  = invoice.seller
    @buyer   = invoice.customer
  end

  def generate
    xml         = ZugferdXmlGenerator.new(@invoice).generate
    pdf_content = build_pdf
    embed_xml_into_pdf(pdf_content, xml)
  end

  private


  def build_pdf
    pdf = Prawn::Document.new(page_size: "A4", margin: [ 50, 55, 50, 55 ])
    pdf.font "Helvetica"
    pdf.font_size 10
    Prawn::Fonts::AFM.hide_m17n_warning = true

    top_y = pdf.cursor

    # ── Oben links: Käufer ──────────────────────────────────
    pdf.bounding_box([ 0, top_y ], width: 240) do
      pdf.text @buyer.name, size: 10
      pdf.text @buyer.street, size: 10
      pdf.text "#{@buyer.postal_code} #{@buyer.city}", size: 10
    end

    # ── Oben rechts: Verkäufer ──────────────────────────────
    pdf.bounding_box([ 320, top_y ], width: 215) do
      pdf.text @seller.name, size: 10
      pdf.text @seller.street, size: 10
      pdf.text "#{@seller.postal_code} #{@seller.city}", size: 10
      pdf.move_down 6
      pdf.text "Tel.: #{@seller.phone}", size: 9, color: "333333" if @seller.phone.present?
      pdf.text "Steuernummer: #{@seller.tax_id}", size: 9, color: "333333" if @seller.tax_id.present?
      pdf.text "USt-IdNr: #{@seller.vat_id}", size: 9, color: "333333" if @seller.vat_id.present?
    end

    # Cursor unter Adressen setzen
    pdf.move_cursor_to top_y - 90
    pdf.move_down 30

    # ── Überschrift ─────────────────────────────────────────
    pdf.text "Rechnung", size: 18, style: :bold
    pdf.move_down 50

    # ── Rechnungsdetails ────────────────────────────────────
    details = [
      [ "Rechnungsdatum:",    @invoice.issue_date.strftime("%d.%m.%Y") ],
      [ "Rechnuns-Nr.:",      @invoice.number ],
      [ "Projekt-Nr.:",       @invoice.order_reference.presence || "—" ],
      [ "Projekttitel:",      @invoice.project_title.presence || "—" ],
      [ "Projektleiter:",     @invoice.project_manager.presence || "—" ],
      [ "Projektort:",        @invoice.production_location.presence || "—" ],
      [ "Leistungszeitraum:", leistungszeitraum ]
    ]

    details.each do |label, value|
      y = pdf.cursor
      pdf.bounding_box([ 0, y + 10 ], width: 155) do
        pdf.text label, size: 10
      end
      pdf.bounding_box([ 155, y + 10 ], width: 380) do
        pdf.text value, size: 10
      end
      pdf.move_down 14
    end

    pdf.move_down 14

    # ── Einleitungstext ─────────────────────────────────────
    intro = @invoice.intro_text.presence ||
    "Hiermit stelle ich Ihnen für meine auftragsgemäß erbrachte Leistung als Fachkraft für " \
    "Veranstaltungstechnik für das oben genannte Projekt folgenden Betrag in Rechnung:"

    pdf.text intro, size: 10, leading: 3
    pdf.move_down 20

    # ── Positionen ──────────────────────────────────────────
    col_widths = [ pdf.bounds.width - 225, 75, 75, 75 ]
    spice = @buyer.name == "Spice Event GmbH"

    if spice
      header = [ [
        { content: "Tätigkeit",  background_color: "f0f0f0", font_style: :bold, size: 9, borders: [ :top, :bottom, :left ] },
        { content: "",  background_color: "f0f0f0", font_style: :bold, size: 9, align: :right, borders: [ :top, :bottom ] },
        { content: "",  background_color: "f0f0f0", font_style: :bold, size: 9, align: :right,  borders: [ :top, :bottom ] },
        { content: "Preis",      background_color: "f0f0f0", font_style: :bold, size: 9, align: :right,  borders: [ :top, :bottom, :right ] }
        ] ]

      rows = @invoice.invoice_items.map do |item|
        [
          { content: item.description, size: 9, borders: [ :top, :bottom, :left ] },
          { content: "", size: 9, align: :right,  borders: [ :top, :bottom ] },
          { content: "", size: 9, align: :right,  borders: [ :top, :bottom ] },
          { content: "#{fmt(item.line_net_amount)} €", size: 9, align: :right, borders: [ :top, :bottom, :right ] }
        ]
      end
    else
      header = [ [
        { content: "Tätigkeit",  background_color: "f0f0f0", font_style: :bold, size: 9 },
          { content: "Einheiten",  background_color: "f0f0f0", font_style: :bold, size: 9, align: :right },
          { content: "Pauschale",  background_color: "f0f0f0", font_style: :bold, size: 9, align: :right },
          { content: "Preis",      background_color: "f0f0f0", font_style: :bold, size: 9, align: :right }
          ] ]
      rows = @invoice.invoice_items.map do |item|
        [
          { content: item.description, size: 9 },
          { content: item.quantity.to_s, size: 9, align: :right },
          { content: "#{fmt(item.unit_price)} €", size: 9, align: :right },
          { content: "#{fmt(item.line_net_amount)} €", size: 9, align: :right }
        ]
      end
    end


    subtotal_row = [ [
      { content: "Zwischensumme", size: 9, font_style: :bold, borders: [ :top ], border_color: "dddddd" },
      { content: "", borders: [ :top ], border_color: "dddddd" },
      { content: "", borders: [ :top ], border_color: "dddddd" },
      { content: "#{fmt(@invoice.net_amount)} €", size: 9, align: :right, borders: [ :top ], border_color: "dddddd" }
    ] ]

    tax_row = [ [
      { content: "Umsatzsteuer", size: 9, font_style: :bold, borders: [], border_color: "dddddd" },
      { content: "#{@invoice.tax_rate.to_i}%", borders: [], border_color: "dddddd" },
      { content: "", borders: [], border_color: "dddddd" },
      { content: "#{fmt(@invoice.tax_amount)} €", size: 9, align: :right, borders: [], border_color: "dddddd" }
    ] ]

    total_row = [ [
      { content: "Gesamtbetrag", size: 10, font_style: :bold, borders: [ :top ], border_color: "333333" },
      { content: "", borders: [ :top ], border_color: "333333" },
      { content: "", borders: [ :top ], border_color: "333333" },
      { content: "#{fmt(@invoice.gross_amount)} €", size: 10, font_style: :bold, align: :right, borders: [ :top ], border_color: "333333", border_width: 10 }
    ] ]

    pdf.table(header + rows + subtotal_row + tax_row + total_row,
      column_widths: col_widths,
      cell_style: { padding: [ 6, 8 ], border_color: "dddddd", border_width: 0.5 }
    )

    pdf.move_down 30

    # ── Zahlungsaufforderung ────────────────────────────────
    zahlungstext = "Bitte zahlen Sie den Gesamtbetrag von #{fmt(@invoice.gross_amount)}€ binnen 14 Tagen nach Erhalt der Rechnung unter Angabe der Rechnungsnummer auf das folgende Konto:\n\n"
    zahlungstext += "#{@seller.name}, ING DiBA,"
    zahlungstext += ", IBAN: #{@seller.iban}" if @seller.iban.present?
    zahlungstext += ", BIC: #{@seller.bic}" if @seller.bic.present?

    pdf.text zahlungstext, size: 10, leading: 3
    pdf.move_down 20

    # ── Grußformel ──────────────────────────────────────────
    pdf.move_down 10
    pdf.text "Mit freundlichen Grüßen,", size: 10
    pdf.move_down 20
    pdf.text @seller.name, size: 10

    pdf.render
  end

  def embed_xml_into_pdf(pdf_content, xml_content)
    doc = HexaPDF::Document.new(io: StringIO.new(pdf_content))

    doc.catalog[:Metadata] = zugferd_metadata(doc)

    ef = doc.add({ Type: :EmbeddedFile, Subtype: :"text/xml" })
    ef.stream = xml_content

    filespec = doc.add({
      Type: :Filespec,
      F: "factur-x.xml",
      UF: "factur-x.xml",
      EF: { F: ef },
      Desc: "Factur-X/ZUGFeRD 2.3",
      AFRelationship: :Data
    })

    (doc.catalog[:Names] ||= doc.add({}))[:EmbeddedFiles] = doc.add({
      Names: [ "factur-x.xml", filespec ]
    })

    out = StringIO.new
    doc.write(out)
    out.string
  end

  def zugferd_metadata(doc)
    stream = doc.add({ Type: :Metadata, Subtype: :XML })
    stream.stream = xmp_metadata
    stream
  end

  def xmp_metadata
    <<~XMP
      <?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description xmlns:fx="urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#">
            <fx:DocumentType>INVOICE</fx:DocumentType>
            <fx:DocumentFileName>factur-x.xml</fx:DocumentFileName>
            <fx:Version>1.0</fx:Version>
            <fx:ConformanceLevel>EN 16931</fx:ConformanceLevel>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>
      <?xpacket end="w"?>
    XMP
  end

  def leistungszeitraum
    if @invoice.delivery_date.present? && @invoice.service_period_end.present?
      "#{@invoice.delivery_date.strftime("%d.%m.%Y")} – #{@invoice.service_period_end.strftime("%d.%m.%Y")}"
    elsif @invoice.delivery_date.present?
      @invoice.delivery_date.strftime("%d.%m.%Y")
    else
      "—"
    end
  end

  def fmt(amount)
    "%.2f" % amount.to_f
  end
end
