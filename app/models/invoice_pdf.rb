require "prawn"
require "prawn/table"

class InvoicePdf
  INK = "101048"
  IVORY = "F7F3EC"
  MUTED = "5C5C7A"

  def initialize(order)
    @order = order
  end

  def render
    pdf = Prawn::Document.new(page_size: "A4", margin: 48, compress: false)
    header(pdf)
    parties(pdf)
    lines(pdf)
    totals(pdf)
    pdf.render
  end

  private

  def header(pdf)
    top = pdf.cursor
    pdf.fill_color INK
    pdf.fill_rectangle [ 0, top ], pdf.bounds.width, 72
    pdf.fill_color IVORY
    pdf.text_box "DeNshe", at: [ 16, top - 16 ], width: pdf.bounds.width - 32, size: 22, style: :bold
    pdf.text_box "Invoice", at: [ 16, top - 42 ], width: pdf.bounds.width - 32, size: 11
    pdf.fill_color INK
    pdf.move_down 92
  end

  def parties(pdf)
    pdf.text @order.number.to_s, size: 14, style: :bold
    pdf.move_down 4
    pdf.fill_color MUTED
    pdf.text @order.created_at.in_time_zone.strftime("%-d %B %Y"), size: 10
    pdf.text @order.channel.to_s.humanize, size: 10
    pdf.fill_color INK
    pdf.move_down 16
    pdf.text "Billed to", size: 9, style: :bold
    pdf.move_down 4
    pdf.text @order.customer_display_name, size: 11
    phone = @order.customer&.phone.presence || @order.guest_phone
    email = @order.customer&.email.presence || @order.guest_email
    pdf.fill_color MUTED
    pdf.text phone.to_s, size: 10 if phone.present?
    pdf.text email.to_s, size: 10 if email.present?
    pdf.fill_color INK
    pdf.move_down 22
  end

  def lines(pdf)
    rows = [ [ "Piece", "Qty", "Price", "Discount", "Amount" ] ]
    @order.order_items.each do |item|
      rows << [
        item.name,
        item.quantity.to_s,
        money(item.unit_price),
        item.discount_amount.to_d.positive? ? money(item.discount_amount) : "-",
        money(item.line_total)
      ]
    end

    pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { borders: [], padding: [ 7, 4 ], size: 10 }) do
      row(0).font_style = :bold
      row(0).background_color = IVORY
      row(0).text_color = INK
      columns(1..4).align = :right
    end
    pdf.move_down 18
  end

  def totals(pdf)
    rows = [ [ "Pieces", money(@order.subtotal) ] ]
    rows << [ "Coupon #{@order.coupon_code}", "- #{money(@order.coupon_discount)}" ] if @order.coupon_code.present?
    rows << [ "Voucher #{@order.voucher_name}", "- #{money(@order.voucher_discount)}" ] if @order.voucher_name.present?
    rows << [ "Shipping", @order.shipping_amount.to_d.zero? ? "Complimentary" : money(@order.shipping_amount) ]
    rows << [ "Total", money(@order.total) ]
    rows << [ "Amount paid", amount_paid_label ]
    if balance?
      rows << [ "Balance", money(@order.total - @order.amount_paid) ]
    end

    pdf.table(rows, width: 260, position: :right, cell_style: { borders: [], padding: [ 4, 0 ], size: 11 }) do
      columns(1).align = :right
      rows.each_with_index do |(label, _), index|
        row(index).font_style = :bold if [ "Total", "Amount paid", "Balance" ].include?(label)
      end
    end

    pdf.move_down 28
    pdf.fill_color MUTED
    pdf.text "Thank you.", size: 10
    pdf.text "denshe.shop", size: 9
    pdf.fill_color INK
  end

  def amount_paid_label
    return "Gifted by the owner" if @order.payment_method == "owner_gift"
    return "Not collected yet" if @order.amount_paid.nil?

    money(@order.amount_paid)
  end

  def balance?
    return false if @order.payment_method == "owner_gift" || @order.amount_paid.nil?

    @order.total.to_d > @order.amount_paid.to_d
  end

  def money(amount)
    value = amount.to_d
    formatted = value == value.to_i ? value.to_i.to_s : format("%.2f", value)
    @order.australia? ? "A$#{formatted}" : "Rs #{formatted}"
  end
end
