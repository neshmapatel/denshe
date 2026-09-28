# A piece sitting in someone's cart. Stock stays untouched until an order is
# fulfilled; this only stops a second shopper from selecting the same units.
class CartHold < ApplicationRecord
  # Forgotten selections let go of the piece so it does not stay locked.
  HOLD_FOR = 2.hours

  belongs_to :product

  validates :session_key, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  def self.fresh
    where(updated_at: HOLD_FOR.ago..)
  end

  def self.release_stale!
    where(updated_at: ...HOLD_FOR.ago).delete_all
  end

  # Units reserved by every cart except the one asking.
  def self.quantities_held_by_others(session_key)
    release_stale!
    fresh.where.not(session_key: session_key).group(:product_id).sum(:quantity)
  end
end