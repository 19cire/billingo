class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  UNIT_CODES = {
    "C62" => "Stück",
    "HUR" => "Stunde",
    "DAY" => "Tag",
    "MON" => "Monat",
    "KGM" => "Kilogramm",
    "MTR" => "Meter"
  }.freeze

  validates :description, presence: true
  validates :quantity,    presence: true, numericality: { greater_than: 0 }
  validates :unit_price,  presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_line_total

  def line_total
    quantity.to_f * unit_price.to_f
  end

  def tax_total
    line_total * (tax_rate.to_f / 100)
  end

  private

  def calculate_line_total
    self.line_net_amount = quantity.to_f * unit_price.to_f
    self.tax_category  ||= "S"
    self.unit_code     ||= "C62"
    self.position      ||= invoice.invoice_items.count + 1
  end
end
