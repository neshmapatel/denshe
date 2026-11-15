class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  has_many :orders, class_name: "Order", foreign_key: :ahoy_visit_id, dependent: :nullify
  belongs_to :user, optional: true

  scope :from_instagram, -> { where("utm_source ILIKE ? OR referrer ILIKE ?", "%instagram%", "%instagram.com%") }
  scope :with_campaign, -> { where.not(utm_campaign: [nil, ""]) }
  scope :recent, -> { order(started_at: :desc) }
end
