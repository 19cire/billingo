class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :seller
  belongs_to :customer
  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items,
    allow_destroy: true,
    reject_if: :all_blank

  STATUSES = %w[draft open paid overdue cancelled].freeze
  validates :number,   presence: true, uniqueness: { scope: :user_id }
  validates :status,   inclusion: { in: STATUSES }
  validates :issue_date, :due_date, presence: true

  before_validation :set_defaults
  before_save :calculate_totals

  scope :open,    -> { where(status: "open") }
  scope :paid,    -> { where(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }

  def total
    gross_amount || 0
  end

  def self.generate_number(user)
    year = Date.today.year
    last = user.invoices.where("number LIKE ?", "#{year}-%")
              .order(:number).last
    next_num = last ? last.number.split("-").last.to_i + 1 : 1
    "#{year}-#{next_num.to_s.rjust(4, '0')}"
  end
  private

  def set_defaults
    self.number           ||= Invoice.generate_number(user) if user
    self.document_type    ||= "380"
    self.currency_code    ||= "EUR"
    self.issue_date       ||= Date.today
    self.status           ||= "draft"
    self.zugferd_profile  ||= "EN_16931"
    self.tax_rate         ||= 19.0
    self.payment_means_code ||= "58"
    self.due_date         ||= Date.today + 14
  end

  def calculate_totals
    if invoice_items.any?
      self.net_amount  = invoice_items.sum { |i| i.quantity.to_f * i.unit_price.to_f }
      self.tax_amount  = net_amount * (tax_rate.to_f / 100)
      self.gross_amount = net_amount + tax_amount
    end
  end
end
