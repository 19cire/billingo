class CreateSellers < ActiveRecord::Migration[8.0]
  def change
    create_table :sellers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :street
      t.string :city
      t.string :postal_code
      t.string :country_code
      t.string :email
      t.string :phone
      t.string :tax_id
      t.string :vat_id
      t.string :iban
      t.string :bic
      t.text :notes

      t.timestamps
    end
  end
end
