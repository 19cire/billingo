class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :street
      t.string :postal_code
      t.string :city
      t.string :country
      t.string :vat_id
      t.string :email
      t.string :phone
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
