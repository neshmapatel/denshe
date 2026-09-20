class AdminUser < ApplicationRecord
  include Ransackable

  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, { admin: 0, super_admin: 1 }

  has_many :inventory_movements, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  def display_name
    name.presence || email
  end

  def to_s
    display_name
  end
end
