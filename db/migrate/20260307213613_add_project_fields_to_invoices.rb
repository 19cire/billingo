class AddProjectFieldsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :project_number, :string
    add_column :invoices, :project_manager, :string
    add_column :invoices, :production_location, :string
    add_column :invoices, :intro_text, :text
  end
end
