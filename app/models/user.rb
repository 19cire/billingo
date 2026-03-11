
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [ :user_name ]

  has_many :sellers,   dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :invoices,  dependent: :destroy

  ROLES = %w[admin user].freeze

  validates :user_name, presence: true, uniqueness: true
  validates :role,      inclusion: { in: ROLES }

  before_validation :set_defaults

  def admin?
    role == "admin"
  end

  def seller_info_complete?
    seller_name.present? && seller_street.present? &&
    seller_city.present? && seller_tax_id.present?
  end

  private

  def set_defaults
    self.role         ||= "user"
    self.country_code ||= "DE" if respond_to?(:country_code)
  end
end
