class InvoicesController < ApplicationController
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_invoice, only: [ :show, :update, :destroy, :download_pdf ]

  def new
    @invoice = current_user.invoices.build
    @invoice.invoice_items.build
  end
  def update
    authorize @invoice
    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: "Rechnung aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @invoice = current_user.invoices.build(invoice_params)
    if @invoice.save
      redirect_to @invoice, notice: "Rechnung erstellt."
    else
      Rails.logger.debug @invoice.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end
  def index
    @invoices = policy_scope(Invoice).order(created_at: :desc)
    @total_amount = @invoices.sum(:gross_amount)
  end

  def show
    authorize @invoice
  end

  def destroy
    authorize @invoice
    @invoice.destroy
    redirect_to invoices_path, notice: "Rechnung gelöscht."
  end

  def download_pdf
    authorize @invoice
    pdf = InvoicePdfGenerator.new(@invoice).generate
    send_data pdf,
      filename: "rechnung-#{@invoice.number}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  private
  def set_invoice
    @invoice = current_user.invoices.find_by(id: params[:id])
    redirect_to invoices_path, alert: "Rechnung nicht gefunden." if @invoice.nil?
  end

  def invoice_params
    params.require(:invoice).permit(
      :seller_id,
      :customer_id, :status, :issue_date, :due_date,
      :delivery_date, :service_period_end, :currency_code, :order_reference,
      :payment_terms, :notes, :project_number, :project_title, :project_manager, :production_location, :intro_text,
      invoice_items_attributes: [
        :id, :description, :quantity, :unit_code,
        :unit_price, :tax_rate, :tax_category, :_destroy
      ]
    )
  end
end
