class InvoicesController < ApplicationController
  def show
    order = Order.find_by!(invoice_token: params[:token])
    send_data order.invoice_pdf,
      filename: "DeNshe-#{order.number}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end
end