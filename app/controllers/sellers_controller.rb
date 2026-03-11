class SellersController < ApplicationController
before_action :authenticate_user!
  def create
    @seller = current_user.sellers.build(seller_params)
    if @seller.save
      redirect_back(fallback_location: new_invoice_path, notice: "Absender gespeichert.")
    else
      redirect_back(fallback_location: new_invoice_path, alert: "Fehler beim Speichern.")
    end
  end

  private

  def seller_params
    params.require(:seller).permit(:name, :street, :city, :postal_code, :country_code, :email, :phone, :tax_id, :vat_id, :iban, :bic)
  end
end
