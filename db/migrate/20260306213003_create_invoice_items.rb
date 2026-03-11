class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :position
      t.string :description
      t.text :detail
      t.decimal :quantity
      t.string :unit_code
      t.decimal :unit_price
      t.decimal :line_net_amount
      t.decimal :tax_rate
      t.string :tax_category

      t.timestamps
    end
  end
end
