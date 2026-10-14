class Customer < ApplicationRecord
  include Ransackable
  include Searchable

  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :coupons, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :email_or_phone

  def self.find_for_contact(email:, phone:)
    if email.present?
      found = where("LOWER(email) = ?", email.strip.downcase).order(:id).first
      return found if found
    end

    key = Coupon.phone_key(phone)
    return if key.blank?

    where("RIGHT(regexp_replace(COALESCE(phone, ''), '\\D', '', 'g'), 10) = ?", key).order(:id).first
  end

  def self.search_columns
    %w[name email phone]
  end

  def to_s
    name
  end

  private

  def email_or_phone
    return if email.present? || phone.present?

    errors.add(:base, "Add an email or a phone number.")
  end
end
