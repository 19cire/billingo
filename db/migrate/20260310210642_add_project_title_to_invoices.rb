class AddProjectTitleToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :project_title, :string
  end
end
