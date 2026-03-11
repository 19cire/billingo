class CustomersController < ApplicationController
  before_action :authenticate_user!

  def create
    @customer = current_user.customers.build(customer_params)
    if @customer.save
      redirect_back(fallback_location: new_invoice_path, notice: "Kunde gespeichert.")
    else
      redirect_back(fallback_location: new_invoice_path, alert: "Fehler beim Speichern.")
    end
  end

  private

  def customer_params
    params.require(:customer).permit(
      :name, :street, :city, :postal_code, :country_code,
      :email, :phone, :vat_id, :tax_id, :buyer_reference,
      :contact_name, :payment_terms, :notes
    )
  end
end
