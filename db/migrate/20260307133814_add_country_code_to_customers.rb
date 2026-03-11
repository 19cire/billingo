class AddCountryCodeToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :country_code, :string
  end
end
