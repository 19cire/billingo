class AddServicePeriodEndToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :service_period_end, :date
  end
end
