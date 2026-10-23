require "test_helper"

class CuratedGiftTest < ActiveSupport::TestCase
  test "seeds default options properly" do
    CuratedGift.seed_defaults!
    assert_equal 5, CuratedGift.count

    little_finds = CuratedGift.find_by!(slug: "little-finds")
    assert_equal "Treasure Drop — Little Finds", little_finds.name
    assert_equal "Little Finds | Mystery Jewellery | ₹499", little_finds.product_title
    assert_equal 499.0, little_finds.price.to_f
    assert little_finds.images.attached?

    signature = CuratedGift.find_by!(slug: "the-signature-edit")
    assert_equal "Treasure Drop — The Signature Edit", signature.name
    assert_equal 1999.0, signature.price.to_f
    assert signature.images.attached?
  end

  test "calculates discount percent when compare_at_price is set" do
    gift = CuratedGift.new(
      name: "Special Drop",
      product_title: "Special Drop | ₹999",
      price: 800,
      compare_at_price: 1000
    )
    gift.valid?
    assert_equal 20.0, gift.discount_percent.to_f
    assert gift.on_sale?
    assert_equal "20%", gift.discount_label
  end
end
