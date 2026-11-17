class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name(
    ENV.fetch("EMAIL_SENDER", "sender@sure.local"),
    "#{Rails.configuration.x.brand_name} #{Rails.configuration.x.product_name}"
  )
  layout "mailer"

  around_action :with_recipient_locale
  before_action :assign_branding

  helper_method :product_name, :brand_name

  private
    def with_recipient_locale(&action)
      recipient = params[:user] || params[:super_admin]
      I18n.with_locale(recipient&.resolved_locale || I18n.default_locale, &action)
    end

    def assign_branding
      @product_name = product_name
      @brand_name = brand_name
    end

    def product_name
      Rails.configuration.x.product_name
    end

    def brand_name
      Rails.configuration.x.brand_name
    end
end
