class InvitationMailer < ApplicationMailer
  def invite_email(invitation)
    @invitation = invitation
    @accept_url = accept_invitation_url(@invitation.token)

    I18n.with_locale(@invitation.family.locale.presence || I18n.default_locale) do
      mail(
        to: @invitation.email,
        subject: t(
          ".subject",
          inviter: @invitation.inviter.display_name,
          product_name: product_name
        )
      )
    end
  end
end
