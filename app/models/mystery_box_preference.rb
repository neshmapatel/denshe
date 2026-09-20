class MysteryBoxPreference < ApplicationRecord
  include Ransackable

  belongs_to :order

  CATEGORY_CHOICES = [
    "earrings",
    "necklaces",
    "bracelets",
    "rings",
    "sets",
    "surprise"
  ].freeze

  FINISH_CHOICES = [
    "gold",
    "silver",
    "rose_gold",
    "surprise"
  ].freeze

  enum :recipient_type, { myself: 0, loved_one: 1, surprise_gift: 2 }
  enum :jewellery_personality, {
    minimal_effortless: 0,
    elegant_timeless: 1,
    bold_statement: 2,
    mix_of_everything: 3
  }
  enum :style_preference, {
    delicate_minimal: 0,
    classic_elegant: 1,
    modern_edgy: 2,
    statement_bold: 3,
    mix_it_up: 4
  }
  enum :jewellery_amount, {
    one_subtle: 0,
    few_together: 1,
    statement_standout: 2,
    amount_surprise: 3
  }
  enum :occasion, {
    everyday: 0,
    work: 1,
    going_out: 2,
    special_occasions: 3,
    occasion_mix: 4
  }

  validates :recipient_type, presence: true
  validates :box_price, numericality: { greater_than_or_equal_to: 0 }
  validates :piece_count_min, :piece_count_max, numericality: { only_integer: true, greater_than: 0 }
  validate :piece_count_range
  validate :preferred_categories_are_known
  validate :preferred_finishes_are_known

  def to_s
    "Mystery box for #{order}"
  end

  def summary_lines
    {
      "Recipient" => recipient_type&.humanize,
      "Personality" => jewellery_personality&.humanize,
      "Preferred pieces" => preferred_categories.map(&:humanize).join(", ").presence,
      "Style" => style_preference&.humanize,
      "How much jewellery" => jewellery_amount&.humanize,
      "Finish" => preferred_finishes.map(&:humanize).join(", ").presence,
      "Occasion" => occasion&.humanize,
      "Personal note" => personal_message,
      "Gift note" => add_gift_note? ? gift_note : "No"
    }.compact_blank
  end

  private

  def piece_count_range
    return if piece_count_min.blank? || piece_count_max.blank?
    return if piece_count_min <= piece_count_max

    errors.add(:piece_count_max, "must be greater than or equal to the minimum piece count")
  end

  def preferred_categories_are_known
    unknown = Array(preferred_categories) - CATEGORY_CHOICES
    errors.add(:preferred_categories, "contains unknown values") if unknown.any?
  end

  def preferred_finishes_are_known
    unknown = Array(preferred_finishes) - FINISH_CHOICES
    errors.add(:preferred_finishes, "contains unknown values") if unknown.any?
  end
end
