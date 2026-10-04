require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 1,
      status: :active
    )
  end

  test "created notifies the order inbox" do
    order = Checkout.new(
      name: "Aisha Shah",
      phone: "9876543210",
      email: "aisha@example.com",
      line1: "14 Sea Face",
      city: "Mumbai",
      state: "Maharashtra",
      pin_code: "400001",
      billing_same: true
    ).place!(Cart.new({}).tap { |cart| cart.add(@product) })

    assert_emails 1 do
      OrderMailer.created(order).deliver_now
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "denshe1713@gmail.com" ], mail.to
    assert_match order.number, mail.subject
    assert_match "Aisha Shah", mail.body.encoded
    assert_match "Aurelia Hoops", mail.body.encoded
  end

  test "placing an order enqueues the notification" do
    assert_enqueued_emails 1 do
      Checkout.new(
        name: "Aisha Shah",
        phone: "9876543210",
        email: "aisha@example.com",
        line1: "14 Sea Face",
        city: "Mumbai",
        state: "Maharashtra",
        pin_code: "400001",
        billing_same: true
      ).place!(Cart.new({}).tap { |cart| cart.add(@product) })
    end
  end
end
