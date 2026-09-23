class Supplier < ApplicationRecord
  include Ransackable

  has_many :purchases, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end

  def location
    [ area, city, state ].compact_blank.join(", ")
  end
end
