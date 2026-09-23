class Purchase < ApplicationRecord
  include Ransackable

  belongs_to :supplier
  belongs_to :funded_by, class_name: "Investor", optional: true
  has_many :products, dependent: :restrict_with_error
  has_many :investments, dependent: :nullify

  validates :reference, presence: true, uniqueness: true
  validates :article_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :merchandise_total, :courier_charge, :tax_amount, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :total_matches_components

  def to_s
    reference
  end

  def landed_cost_per_article
    return 0 if article_count.to_i.zero?

    (total_amount.to_d / article_count).round(2)
  end

  private

  def total_matches_components
    return if merchandise_total.nil? || courier_charge.nil? || tax_amount.nil? || total_amount.nil?

    expected = merchandise_total.to_d + courier_charge.to_d + tax_amount.to_d
    return if expected == total_amount.to_d

    errors.add(:total_amount, "must equal merchandise plus courier plus tax")
  end
end
