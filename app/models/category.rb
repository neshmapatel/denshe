class Category < ApplicationRecord
  include Ransackable
  include Searchable
  include Sluggable

  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :name) }

  def self.search_columns
    %w[name slug]
  end

  def to_s
    name
  end
end
