class AdminUser < ApplicationRecord
  include Ransackable
  include Searchable

  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, { admin: 0, super_admin: 1 }

  has_many :inventory_movements, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  def self.search_columns
    %w[name email]
  end

  def display_name
    name.presence || email
  end

  def to_s
    display_name
  end
end
