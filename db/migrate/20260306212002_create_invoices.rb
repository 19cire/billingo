class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :number
      t.string :document_type
      t.date :issue_date
      t.date :due_date
      t.date :delivery_date
      t.date :payment_date
      t.string :status
      t.string :zugferd_profile
      t.string :currency_code
      t.decimal :tax_rate
      t.string :tax_category
      t.decimal :tax_amount
      t.decimal :net_amount
      t.decimal :gross_amount
      t.string :payment_terms
      t.string :payment_means_code
      t.string :order_reference
      t.string :contract_reference
      t.text :notes

      t.timestamps
    end
  end
end
