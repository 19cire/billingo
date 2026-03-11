class AddSellerToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_reference :invoices, :seller, null: false, foreign_key: true
  end
end
