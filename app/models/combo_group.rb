class ComboGroup < ApplicationRecord
  include Ransackable

  belongs_to :combo, inverse_of: :groups
  has_many :options, -> { order(:position, :id) }, class_name: "ComboOption", inverse_of: :combo_group, dependent: :destroy
  has_many :products, through: :options

  validates :name, presence: true
  validates :choose_count, numericality: { only_integer: true, greater_than: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def selected_product_ids
    return @selected_product_ids if instance_variable_defined?(:@selected_product_ids)

    product_ids
  end

  def selected_product_ids=(ids)
    @selected_product_ids = Array(ids).reject(&:blank?).map(&:to_i).uniq
  end

  def pending_product_ids
    instance_variable_defined?(:@selected_product_ids) ? @selected_product_ids : product_ids
  end

  after_save :assign_selected_products, if: -> { instance_variable_defined?(:@selected_product_ids) }

  private

  def assign_selected_products
    return if product_ids.sort == @selected_product_ids.sort

    self.product_ids = @selected_product_ids
  end
end
