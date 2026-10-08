class Combo < ApplicationRecord
  include Ransackable
  include Sluggable

  has_many :groups, -> { order(:position, :id) }, class_name: "ComboGroup", inverse_of: :combo, dependent: :destroy

  accepts_nested_attributes_for :groups, allow_destroy: true, reject_if: :all_blank

  enum :status, { draft: 0, active: 1 }

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :ready_to_offer, if: :active?

  scope :ordered, -> { order(:position, :name) }

  def to_s
    name
  end

  def choice_summary
    groups.map { |group| "#{group.choose_count} from #{group.name}" }.to_sentence
  end

  private

  def ready_to_offer
    live = groups.reject(&:marked_for_destruction?)
    errors.add(:base, "Add at least one choice.") if live.empty?

    ids = live.flat_map(&:pending_product_ids)
    errors.add(:base, "A piece can only sit in one choice.") if ids.uniq.size != ids.size

    live.each do |group|
      next if group.choose_count.to_i.positive? && group.pending_product_ids.size >= group.choose_count.to_i

      label = group.name.presence || "A choice"
      errors.add(:base, "#{label}: the shopper can pick #{group.choose_count}, so add at least that many pieces.")
    end
  end
end
