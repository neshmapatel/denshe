class Investor < ApplicationRecord
  include Ransackable
  include Searchable

  belongs_to :admin_user, optional: true
  has_many :investments, dependent: :restrict_with_error
  has_many :funded_purchases, class_name: "Purchase", foreign_key: :funded_by_id, inverse_of: :funded_by, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def self.search_columns
    %w[name email]
  end

  def to_s
    name
  end

  def total_invested
    investments.sum(:amount)
  end

  def share_percent(of_total)
    return 0 if of_total.to_d <= 0

    ((total_invested / of_total.to_d) * 100).round(2)
  end
end
