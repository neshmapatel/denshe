class ComboOption < ApplicationRecord
  include Ransackable

  belongs_to :combo_group, inverse_of: :options
  belongs_to :product

  validates :product_id, uniqueness: { scope: :combo_group_id }
end
