require "test_helper"

class StorefrontFlowTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 1,
      status: :active,
      colour: "gold",
      material: "Anti-tarnish",
      short_description: "Small hoops for every day.",
      new_arrival: true
    )
  end

  test "public pages tell search engines what they are" do
    get root_url
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_select "title", "Gold-tone earrings and everyday jewellery · DeNshe Jewellery"
    assert_select "meta[name=description]"
    assert_match "Anand", response.body
    assert_no_match "from Mumbai", response.body
    assert_match "Organization", response.body
    assert_select "meta[name=robots][content=?]", "index, follow"

    get piece_path(@product.slug)
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/pieces/#{@product.slug}"
    assert_match "schema.org/InStock", response.body
    assert_match "699.00", response.body

    get cart_path
    assert_select "meta[name=robots][content=?]", "noindex, follow"

    get sitemap_path
    assert_response :success
    assert_match piece_url(@product.slug), response.body
    assert_match catalogue_url, response.body
    assert_match collection_url("western"), response.body
    assert_no_match %r{/cart}, response.body
    assert_no_match %r{/admin}, response.body

    draft = Product.create!(
      category: @category,
      name: "Hidden Kada",
      selling_price: 400,
      stock_quantity: 1,
      status: :draft
    )
    get sitemap_path
    assert_no_match piece_url(draft.slug), response.body

    get "/robots.txt"
    assert_response :success
    assert_match "Sitemap: https://denshe.shop/sitemap.xml", response.body
    assert_match "Disallow: /admin", response.body
  end

  test "photographs describe the piece, and later pages keep their own title" do
    attach_product_image(@product, "hoops.png")
    @product.ensure_primary_image!

    get shop_path
    assert_select "article.piece img[alt=?]", "Aurelia Hoops, earrings"

    get collections_path
    assert_select "a.collection-tile[href='#{collection_path(@category.slug)}'] img[alt=?]", "Gold-tone earring designs"

    get piece_path(@product.slug)
    assert_select ".gallery img[alt=?]", "Aurelia Hoops, earrings"

    get catalogue_path
    assert_select ".catalogue-card img[alt=?]", "Aurelia Hoops, earrings"

    24.times do |index|
      Product.create!(
        category: @category,
        name: "Hoop #{index}",
        selling_price: 500,
        stock_quantity: 1,
        status: :active
      )
    end

    get shop_path(page: 2)
    assert_response :success
    assert_select "title", "Shop, page 2 · DeNshe Jewellery"
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/shop?page=2"
  end

  test "a product link with a stray space opens the clean address" do
    @product.update_column(:slug, "aurelia-hoops ")

    get "/pieces/aurelia-hoops%20"
    assert_redirected_to piece_path("aurelia-hoops")
    follow_redirect!
    assert_response :success
    assert_select "h1", "Aurelia Hoops"

    get "/pieces/aurelia-hoops"
    assert_response :success

    get sitemap_path
    assert_match piece_url("aurelia-hoops"), response.body
    assert_no_match "%20", response.body
  end

  test "indian festive collection waits until a piece is active" do
    get collection_path("indian")

    assert_response :success
    assert_match "Hang tight, something festive is brewing", response.body
    assert_match "The Festive Edit is almost ready to meet you", response.body
    assert_match "We’re putting the finishing touches on it", response.body
    assert_match "See you soon", response.body
    assert_select "article.piece", 0

    get collections_path
    assert_select "a.collection-tile[href='#{collection_path('indian')}']", text: /Coming soon/
    assert_select "a.collection-tile[href='#{collection_path('western')}']", text: /The Modern Edit/

    held = Product.create!(
      category: @category,
      name: "Draft Jhumka",
      selling_price: 999,
      stock_quantity: 1,
      status: :draft,
      collection_line: :indian
    )
    get collection_path("indian")
    assert_match "Hang tight, something festive is brewing", response.body

    held.update!(status: :active)
    get collection_path("indian")
    assert_select "h1", "The Festive Edit"
    assert_select "article.piece", 1
    assert_no_match "Hang tight", response.body

    get collection_path("western")
    assert_select "h1", "The Modern Edit"
    assert_select "article.piece", text: /Aurelia Hoops/
    assert_select "article.piece", text: /Draft Jhumka/, count: 0
  end

  test "home introduces the cabinet" do
    get root_url

    assert_response :success
    assert_select "h1", /chosen to feel like you/i
    assert_match "A touch of sparkle, for the season ahead.", response.body
    assert_match "See something you love?", response.body
    assert_select "img[alt='DeNshe Jewellery']"
    assert_no_match "Pieces we’re loving right now", response.body
    assert_no_match "View collection", response.body
  end

  test "shop, collection, and piece pages render" do
    get shop_path
    assert_response :success
    assert_select "h1", "Every piece"
    assert_select "article.piece", 1

    get shop_path, params: { material: "Anti-tarnish", sort: "price-asc" }
    assert_response :success
    assert_select "article.piece", 1

    get shop_path, params: { material: "Missing metal" }
    assert_response :success
    assert_select "h2", "Nothing matches."

    get collection_path(@category.slug)
    assert_response :success
    assert_select "h1", "Earrings"
    assert_match "Gold-tone and anti-tarnish earring designs", response.body

    bracelets = Category.create!(name: "Bracelets", position: 2)
    Product.create!(
      category: bracelets,
      name: "Link Bracelet",
      selling_price: 499,
      purchase_price: 120,
      stock_quantity: 1,
      status: :active,
      collection_line: :western
    )
    Product.create!(
      category: @category,
      name: "Festive Jhumkas",
      selling_price: 1299,
      purchase_price: 400,
      stock_quantity: 2,
      status: :active,
      collection_line: :indian
    )
    get collections_path
    assert_response :success
    assert_select "a.collection-tile[href='#{collection_path('western')}']", text: /The Modern Edit/
    assert_select "a.collection-tile[href='#{collection_path('indian')}']", text: /The Festive Edit/
    assert_select "a.collection-tile[href='#{collection_path(bracelets.slug)}'] img[src*='collection-bracelets']"
    assert_select "a.collection-tile[href='#{collection_path(@category.slug)}'] img[src*='collection-earrings']"

    get collection_path("indian")
    assert_response :success
    assert_select "h1", "The Festive Edit"
    assert_select "article.piece", 1
    assert_select ".piece__meta", /The Festive Edit/

    get collection_path("western")
    assert_response :success
    assert_select "h1", "The Modern Edit"

    pendants = Category.create!(name: "Chain Pendants", position: 3)
    Product.create!(
      category: pendants,
      name: "Wave Pendant",
      selling_price: 799,
      purchase_price: 200,
      stock_quantity: 1,
      status: :active
    )
    get collections_path
    assert_select "a.collection-tile[href='#{collection_path(pendants.slug)}'] img[src*='collection-chain-pendants']"

    get piece_path(@product.slug)
    assert_response :success
    assert_select "h1", "Aurelia Hoops"
    assert_select "dialog.lightbox"
    assert_select "button.lightbox__cancel", text: "Cancel"
    assert_select ".piece-note__kicker", "A little more personal."
    assert_select ".piece-note", /single piece/

    @product.clips.attach(io: StringIO.new("clip-bytes"), filename: "turn.mp4", content_type: "video/mp4")
    get piece_path(@product.slug)
    assert_select "video.clips__player", 1
  end

  test "story, care, contact, mystery box, and jewellery box render" do
    get story_path
    assert_response :success
    assert_select "h1", /two friends/i
    assert_select "h2", text: "Okay, but who are we?"
    assert_select "p.story__moment", text: /Let's actually do it/
    assert_select "h2", text: "Worn your way."
    assert_no_match "googletagmanager.com/gtag/js", response.body

    get care_path
    assert_response :success
    assert_select "h1", /care guide/i

    attach_product_image(@product, "catalogue.png")
    @product.ensure_primary_image!
    supplier = Supplier.create!(name: "Catalogue Supplier")
    purchase = Purchase.create!(
      supplier: supplier,
      reference: "MV-LOT-001",
      article_count: 1,
      merchandise_total: 180,
      courier_charge: 0,
      total_amount: 180
    )
    @product.update!(purchase: purchase)
    Product.create!(
      category: @category,
      name: "Hidden Draft",
      selling_price: 100,
      stock_quantity: 1,
      status: :draft
    )

    get catalogue_path
    assert_response :success
    assert_select "h1", /every piece, with its price/i
    assert_select "article.catalogue-card", 1
    assert_select ".catalogue-card__batch", text: "Batch MV-LOT-001"
    assert_select ".catalogue-card__facts dd", text: "₹699"
    assert_select ".catalogue-card__facts dd", text: "1"
    assert_no_match "Hidden Draft", response.body
    assert_select "button[data-fullscreen-src]", 1
    assert_select "dialog.lightbox"
    assert_select "button.lightbox__cancel", text: "Cancel"
    assert_match "Catalogue", response.body

    get contact_path
    assert_response :success
    assert_select "h1", /write to us/i

    get privacy_path
    assert_response :success
    assert_select "h1", /privacy/i
    assert_match "DeNshe Jewellery", response.body
    assert_match "Google Analytics", response.body

    get terms_path
    assert_response :success
    assert_select "h1", /terms/i
    assert_match "DeNshe Jewellery", response.body

    get shipping_returns_path
    assert_response :success
    assert_select "h1", /shipping/i
    assert_match "₹80", response.body
    assert_match "DeNshe Jewellery", response.body

    get mystery_box_path
    assert_response :success
    assert_select "h1", /box/i
    assert_no_match "See something you love?", response.body
    assert_select "[data-controller='fitting']"
    assert_select "[data-fitting-value-param='799']", text: /799/
    assert_select "[data-fitting-value-param='899']", text: /899/
    assert_select "[data-fitting-value-param='1199']", text: /1,199/
    assert_no_match "Send by email", response.body

    get jewellery_box_path
    assert_response :success
    assert_select "h1", /jewellery box/i
  end

  test "google analytics tag appears when a measurement id is set" do
    previous = Rails.application.config.x.google_analytics_id
    Rails.application.config.x.google_analytics_id = "G-TESTONLY123"

    get root_path
    assert_response :success
    assert_match "googletagmanager.com/gtag/js?id=G-TESTONLY123", response.body
    assert_match 'gtag("config", "G-TESTONLY123"', response.body
  ensure
    Rails.application.config.x.google_analytics_id = previous
  end

  test "a mystery box continues to name, shipping, and payment" do
    get mystery_box_details_path
    assert_redirected_to mystery_box_path

    post mystery_box_path, params: {
      mystery_box: {
        box: "899",
        recipient: "myself",
        personality: "minimal_effortless",
        occasion: "everyday",
        pieces: [ "earrings" ],
        finish: [ "gold" ],
        note: "Gold hoops."
      }
    }
    assert_redirected_to mystery_box_details_path
    follow_redirect!
    assert_match "We have recorded your response", response.body

    assert_difference -> { Order.mystery_box.count }, 1 do
      post mystery_box_details_path, params: {
        checkout: {
          name: "Aisha Shah",
          phone: "9876543210",
          email: "aisha@example.com",
          line1: "14 Sea Face",
          city: "Mumbai",
          state: "Maharashtra",
          pin_code: "400001",
          billing_same: "1"
        }
      }
    end
    assert_redirected_to checkout_payment_path
    order = Order.mystery_box.order(:id).last
    assert_equal 80, order.shipping_amount
    assert_equal 979, order.total
    preference = order.mystery_box_preference
    assert_equal 6, preference.piece_count_min
    assert_equal 7, preference.piece_count_max
    assert_equal "Gold hoops.", preference.personal_message
    follow_redirect!
    assert_match "Mystery box, 6 to 7 pieces", response.body
  end

  test "a selected piece can be checked out through to payment" do
    get shop_path
    assert_select "button", text: /Select/

    post cart_items_path, params: { slug: @product.slug }
    assert_redirected_to shop_path

    follow_redirect!
    assert_select "a", text: /Selected/

    get cart_path
    assert_response :success
    assert_select "h1", /selected pieces/i
    assert_select "a", text: "Aurelia Hoops"

    get checkout_path
    assert_response :success
    assert_select "h1", /where should we send it/i

    post checkout_path, params: { checkout: { name: "", phone: "9876543210", line1: "14 Sea Face", city: "Mumbai", state: "Maharashtra", pin_code: "400001", billing_same: "1" } }
    assert_response :unprocessable_entity

    post checkout_path, params: {
      checkout: {
        name: "Aisha Shah",
        phone: "9876543210",
        email: "aisha@example.com",
        line1: "14 Sea Face",
        city: "Mumbai",
        state: "Maharashtra",
        pin_code: "400001",
        billing_same: "1"
      }
    }
    assert_redirected_to checkout_payment_path

    follow_redirect!
    assert_response :success
    assert_select "h1", "Payment."
    assert_match(/nothing has been charged/i, response.body)
    assert_match(/Aisha Shah/, response.body)
    assert_match(/14 Sea Face/, response.body)

    order = Order.order(:id).last
    assert_equal "unpaid", order.payment_status
    assert_equal "Aurelia Hoops", order.order_items.sole.name
    assert_equal 0, @product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count
    assert_equal 0, Cart.new(session).count

    get shop_path
    assert_response :success
    assert_match "Aurelia Hoops", response.body
    assert_select "article.piece--sold .badge--sold", text: /sold out/i
  end

  test "another shopper sees a piece that is already in a cart" do
    get piece_path(@product.slug)
    assert_match "1 available", response.body

    post cart_items_path, params: { slug: @product.slug }

    open_session do |other|
      other.get piece_path(@product.slug)
      other.assert_no_match "1 available", other.response.body
      other.assert_select "p.stock-note", text: "Someone has already added this to their cart."
      other.assert_select "button", text: /Select/, count: 0

      other.get shop_path
      other.assert_match "Someone has already added this to their cart.", other.response.body

      other.post cart_items_path, params: { slug: @product.slug }
      other.assert_redirected_to shop_path
      other.follow_redirect!
      other.assert_match "Someone has already added Aurelia Hoops to their cart.", other.response.body
    end
  end

  test "available quantity drops by what other carts are holding" do
    @product.update!(stock_quantity: 3)

    post cart_items_path, params: { slug: @product.slug }
    get piece_path(@product.slug)
    assert_match "2 available", response.body
    assert_select "a", text: /Selected/

    open_session do |other|
      other.get piece_path(@product.slug)
      assert_match "2 available", other.response.body
      other.post cart_items_path, params: { slug: @product.slug }
      other.follow_redirect!
    end

    get piece_path(@product.slug)
    assert_match "1 available", response.body
  end

  test "checkout and payment ask for a selection first" do
    get checkout_path
    assert_redirected_to cart_path

    get checkout_payment_path
    assert_redirected_to cart_path

    get checkout_success_path
    assert_redirected_to cart_path
  end

  test "a held storefront shows launching soon until the preview link" do
    previous = Rails.application.config.x.storefront_held
    Rails.application.config.x.storefront_held = true

    get root_url
    assert_response :success
    assert_select "h1", "Launching Soon!"
    assert_select "img[alt='DeNshe Jewellery']"

    get shop_path
    assert_select "h1", "Launching Soon!"
    assert_select "article.piece", 0

    get storefront_preview_path("wrong-token")
    assert_response :not_found

    get storefront_preview_path(Rails.application.config.x.storefront_preview_token)
    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", /chosen to feel like you/i

    get close_storefront_preview_path
    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", "Launching Soon!"
  ensure
    Rails.application.config.x.storefront_held = previous
  end

  test "razorpay payment is verified before the order is marked paid" do
    place_order
    order = Order.order(:id).last

    get checkout_success_path
    assert_redirected_to checkout_payment_path
    fake = Struct.new(:id, :amount, :currency).new("order_test_1", 69900, "INR")
    with_razorpay_orders(Class.new { define_singleton_method(:create) { |*| fake } }) do
      post checkout_razorpay_order_path, as: :json
    end
    assert_response :success
    assert_equal "order_test_1", JSON.parse(response.body).fetch("order_id")

    post checkout_payment_verify_path, params: {
      razorpay_order_id: "order_test_1",
      razorpay_payment_id: "pay_test_1",
      razorpay_signature: "not-the-signature"
    }, as: :json
    assert_response :bad_request
    payment = order.reload.payments.sole
    assert order.payment_failed?
    assert payment.failed?
    assert_equal "Payment could not be verified.", payment.error_message

    post checkout_payment_verify_path, params: { razorpay_order_id: "order_test_1" }, as: :json
    assert_response :bad_request
    assert order.reload.payment_failed?

    signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      ENV.fetch("RAZORPAY_KEY_SECRET"),
      "order_test_1|pay_test_1"
    )
    post checkout_payment_verify_path, params: {
      razorpay_order_id: "order_test_1",
      razorpay_payment_id: "pay_test_1",
      razorpay_signature: signature
    }, as: :json
    assert_response :success
    assert_equal checkout_success_path, JSON.parse(response.body).fetch("redirect")
    assert order.reload.payment_paid?
    assert_equal "pay_test_1", order.payment_reference
    assert_equal "razorpay", order.payment_method
    assert order.payments.sole.paid?
    assert_nil order.payments.sole.error_message
    assert_equal 0, @product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count

    get checkout_payment_status_path, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body.fetch("paid")
    assert_equal false, body.fetch("failed")
    assert_equal checkout_success_path, body.fetch("redirect")

    get checkout_payment_path
    assert_redirected_to checkout_success_path
    follow_redirect!
    assert_select "h1", /Hey/
    assert_match "Your order has been placed", response.body
    assert_match "495894589459", response.body
    assert_match "denshe1713@gmail.com", response.body

    get checkout_success_path
    assert_response :success
  end

  test "razorpay webhook marks the order paid when the browser misses the callback" do
    place_order
    order = Order.order(:id).last
    fake = Struct.new(:id, :amount, :currency).new("order_hook_1", 69900, "INR")
    with_razorpay_orders(Class.new { define_singleton_method(:create) { |*| fake } }) do
      post checkout_razorpay_order_path, as: :json
    end

    previous_secret = ENV["RAZORPAY_WEBHOOK_SECRET"]
    ENV["RAZORPAY_WEBHOOK_SECRET"] = "webhook_test_secret"
    body = {
      event: "payment.captured",
      payload: {
        payment: {
          entity: {
            id: "pay_hook_1",
            order_id: "order_hook_1",
            status: "captured",
            amount: 69900
          }
        }
      }
    }.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", "webhook_test_secret", body)

    post webhooks_razorpay_path,
         params: body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-Razorpay-Signature" => signature
         }

    assert_response :ok
    assert order.reload.payment_paid?
    assert_equal "pay_hook_1", order.payment_reference
    assert order.payments.sole.paid?
    assert_equal 0, @product.reload.stock_quantity

    # Idempotent on a second delivery.
    post webhooks_razorpay_path,
         params: body,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-Razorpay-Signature" => signature
         }
    assert_response :ok
    assert_equal 0, @product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count
  ensure
    ENV["RAZORPAY_WEBHOOK_SECRET"] = previous_secret
  end

  test "a declined card is stored on the payment" do
    place_order
    fake = Struct.new(:id, :amount, :currency).new("order_test_9", 69900, "INR")
    with_razorpay_orders(Class.new { define_singleton_method(:create) { |*| fake } }) do
      post checkout_razorpay_order_path, as: :json
    end

    post checkout_payment_failure_path, params: {
      status: "failed",
      gateway_order_id: "order_test_9",
      gateway_payment_id: "pay_declined",
      error_code: "BAD_REQUEST_ERROR",
      error_message: "International cards are not supported",
      error_source: "business",
      error_step: "payment_authentication",
      error_reason: "international_transaction_not_allowed"
    }, as: :json

    assert_response :success
    order = Order.order(:id).last.reload
    payment = order.payments.sole
    assert order.payment_failed?
    assert payment.failed?
    assert_equal "International cards are not supported", payment.error_message
    assert_equal "international_transaction_not_allowed", payment.error_reason
    assert_equal "pay_declined", payment.gateway_payment_id
    assert_equal "Razorpay", payment.payment_gateway.name
  end

  test "razorpay order creation rejects a tiny amount and reports auth failure" do
    place_order
    Order.order(:id).last.update!(total: 0.5)

    post checkout_razorpay_order_path, as: :json
    assert_response :bad_request

    Order.order(:id).last.update!(total: 699)
    failing = Class.new do
      define_singleton_method(:create) { |*| raise Razorpay::Error.new("BAD_REQUEST_ERROR", 401) }
    end
    with_razorpay_orders(failing) do
      post checkout_razorpay_order_path, as: :json
    end
    assert_response :unauthorized
    order = Order.order(:id).last.reload
    assert order.payment_failed?
    assert_equal "BAD_REQUEST_ERROR", order.payments.sole.error_code
  end

  test "sold pieces stay in the shop with a sold out tag" do
    @product.update!(stock_quantity: 0)

    get piece_path(@product.slug)
    assert_response :success
    assert_select ".badge--sold", text: /sold out/i
    assert_select ".stock-note", /found its person/i

    get shop_path
    assert_response :success
    assert_select "article.piece", 1
    assert_select "article.piece--sold .badge--sold", text: /sold out/i
    assert_select "article.piece button", text: /Select/, count: 0

    get collection_path(@product.category.slug)
    assert_response :success
    assert_select "article.piece--sold .badge--sold", text: /sold out/i
  end

  test "australia shows only priced pieces and records an order without payment" do
    hidden = Product.create!(
      category: @category,
      name: "India Only Studs",
      selling_price: 499,
      stock_quantity: 1,
      status: :active
    )
    @product.update!(visible_in_australia: true, selling_price_aud: 49, compare_at_price_aud: 59)

    get shop_path, headers: { "CF-IPCountry" => "AU" }
    assert_response :success
    assert_select "article.piece", 1
    assert_match "A$49", response.body
    assert_no_match "India Only Studs", response.body
    assert_no_match "Mystery box", response.body

    get piece_path(hidden.slug)
    assert_response :success
    assert_match "Available in India", response.body
    assert_select ".detail__actions button", text: /Select/, count: 0
    assert_select ".detail__actions a", text: /View in the India shop/

    get shop_path(market: "in")
    assert_redirected_to shop_path
    follow_redirect!
    assert_select "article.piece", 2
    assert_match "₹699", response.body

    get shop_path(market: "au")
    follow_redirect!
    post cart_items_path, params: { slug: @product.slug }
    assert_redirected_to shop_path

    get checkout_path
    assert_response :success
    assert_select "button", text: /Place order/
    assert_match "Postcode", response.body
    assert_match "A$49", response.body

    assert_enqueued_emails 1 do
      post checkout_path, params: {
        checkout: {
          name: "Mia Chen",
          phone: "0412345678",
          email: "mia@example.com",
          line1: "18 Crown Street",
          city: "Sydney",
          state: "New South Wales",
          pin_code: "2000",
          billing_same: "1"
        }
      }
    end
    assert_redirected_to checkout_success_path
    follow_redirect!
    assert_match "arrange payment and delivery", response.body
    assert_match "A$49", response.body

    order = Order.order(:id).last
    assert_equal "AUD", order.currency
    assert_equal "unpaid", order.payment_status
    assert_equal 0, @product.reload.stock_quantity
    assert_equal "Australia", order.shipping_address.country
  end

  private

  def with_razorpay_orders(client)
    previous = RazorpayGateway.orders
    RazorpayGateway.orders = client
    yield
  ensure
    RazorpayGateway.orders = previous
  end

  def place_order
    post cart_items_path, params: { slug: @product.slug }
    post checkout_path, params: {
      checkout: {
        name: "Aisha Shah",
        phone: "9876543210",
        email: "aisha@example.com",
        line1: "14 Sea Face",
        city: "Mumbai",
        state: "Maharashtra",
        pin_code: "400001",
        billing_same: "1"
      }
    }
    follow_redirect!
  end
end
