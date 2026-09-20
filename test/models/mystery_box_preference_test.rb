require "test_helper"

class MysteryBoxPreferenceTest < ActiveSupport::TestCase
  test "stores quiz answers against an order" do
    order = Order.create!(order_type: :mystery_box, total: 599)
    preference = MysteryBoxPreference.create!(
      order: order,
      recipient_type: :myself,
      jewellery_personality: :minimal_effortless,
      preferred_categories: %w[earrings necklaces],
      style_preference: :delicate_minimal,
      jewellery_amount: :few_together,
      preferred_finishes: %w[gold],
      occasion: :everyday,
      personal_message: "I got my first promotion!"
    )

    assert preference.persisted?
    assert_equal "earrings", preference.preferred_categories.first
    assert_includes preference.summary_lines.values, "I got my first promotion!"
  end

  test "rejects unknown category answers" do
    order = Order.create!(order_type: :mystery_box, total: 599)
    preference = MysteryBoxPreference.new(
      order: order,
      recipient_type: :myself,
      preferred_categories: %w[watches]
    )

    refute preference.valid?
    assert_includes preference.errors[:preferred_categories], "contains unknown values"
  end
end
