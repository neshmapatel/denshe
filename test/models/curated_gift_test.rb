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

    noor = CuratedGift.find_by!(slug: "noor")
    assert_equal "Treasure Drop — Noor", noor.name
    assert_equal 1999.0, noor.price.to_f
    assert noor.images.attached?
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
