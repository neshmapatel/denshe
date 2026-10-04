class OrderMailer < ApplicationMailer
  def created(order)
    @order = order
    @brand = Rails.application.config.x.brand
    mail(
      to: self.class.notify_email,
      subject: "New DeNshe order #{order.number}"
    )
  end

  def self.notify_created(order)
    return if notify_email.blank?
    return unless delivery_ready?

    created(order).deliver_later
  end

  def self.notify_email
    ENV["ORDER_NOTIFY_EMAIL"].presence ||
      Rails.application.config.x.brand.order_notify_email.presence ||
      Rails.application.config.x.brand.email.presence
  end

  def self.delivery_ready?
    return true if Rails.env.test?
    return true if ActionMailer::Base.delivery_method == :file
    return true if ActionMailer::Base.delivery_method == :test

    ENV["SMTP_ADDRESS"].present?
  end
end

