class AddMissingFieldsToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :tax_id, :string
    add_column :customers, :buyer_reference, :string
    add_column :customers, :contact_name, :string
    add_column :customers, :payment_terms, :string
    add_column :customers, :notes, :text
  end
end
