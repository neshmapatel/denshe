require "test_helper"

class InvestmentTest < ActiveSupport::TestCase
  setup do
    @investor = Investor.create!(name: "Neshma")
  end

  test "accepts a positive amount" do
    investment = Investment.create!(
      investor: @investor,
      kind: :expense,
      amount: 250,
      invested_on: Date.current,
      notes: "Jewellery card"
    )

    assert investment.persisted?
    assert_equal 250, investment.amount
  end

  test "rejects a zero amount" do
    investment = Investment.new(
      investor: @investor,
      kind: :expense,
      amount: 0,
      invested_on: Date.current
    )

    assert_not investment.valid?
    assert_includes investment.errors[:amount], "must be greater than or equal to 0.01"
  end
end
