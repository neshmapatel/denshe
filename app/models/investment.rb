class Investment < ApplicationRecord
  include Ransackable
  include Searchable

  belongs_to :investor
  belongs_to :purchase, optional: true

  enum :kind, { product_purchase: 0, expense: 1, capital: 2 }

  # greater_than: 0 on a decimal breaks the ActiveAdmin form (Formtastic cannot
  # derive an HTML min). Use a small floor instead.
  validates :amount, numericality: { greater_than_or_equal_to: 0.01 }
  validates :kind, presence: true

  def self.search_columns
    %w[notes investors.name purchases.reference]
  end

  def self.search_joins
    [ :investor, :purchase ]
  end

  def to_s
    "₹#{amount} · #{investor.name}"
  end
end
