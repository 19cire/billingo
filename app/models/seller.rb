class Seller < ApplicationRecord
  belongs_to :user
  has_many :invoices, dependent: :nullify

  validates :name,         presence: true
  validates :street,       presence: true
  validates :city,         presence: true
  validates :postal_code,  presence: true
  validates :country_code, presence: true, length: { is: 2 }

  after_initialize { self.country_code ||= "DE" }
end
