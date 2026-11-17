require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  test "background delivery renders the recipient language and restores the worker locale" do
    user = users(:family_admin)
    user.update!(locale: "vi")
    user.family.update!(locale: "en")
    Current.reset

    I18n.with_locale(:en) do
      perform_enqueued_jobs do
        PasswordMailer.with(user: user, token: "reset-token").password_reset.deliver_later
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal [ user.email ], mail.to
      assert_equal I18n.t("password_mailer.password_reset.subject", locale: :vi,
                         product_name: Rails.configuration.x.product_name), mail.subject
      assert_includes (mail.html_part || mail).body.decoded, I18n.t("password_mailer.password_reset.cta", locale: :vi)
      assert_equal :en, I18n.locale
    end
  end

  test "recipient without a locale uses the family language" do
    user = users(:family_admin)
    user.update!(locale: nil)
    user.family.update!(locale: "vi")

    mail = PasswordMailer.with(user: user, token: "reset-token").password_reset

    assert_equal I18n.t("password_mailer.password_reset.subject", locale: :vi,
                       product_name: Rails.configuration.x.product_name), mail.subject
  end

  test "English recipient takes precedence over Vietnamese family" do
    user = users(:family_admin)
    user.update!(locale: "en")
    user.family.update!(locale: "vi")

    I18n.with_locale(:vi) do
      mail = PasswordMailer.with(user: user, token: "reset-token").password_reset
      assert_equal I18n.t("password_mailer.password_reset.subject", locale: :en,
                         product_name: Rails.configuration.x.product_name), mail.subject
      assert_equal :vi, I18n.locale
    end
  end
end
