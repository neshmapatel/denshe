class Supplier < ApplicationRecord
  include Ransackable
  include Searchable

  has_many :purchases, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def self.search_columns
    %w[name phone website area city state pin_code]
  end

  def to_s
    name
  end

  def location
    [ area, city, state ].compact_blank.join(", ")
  end
end
