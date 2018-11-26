class UserNotifierMailer < ApplicationMailer
  default :from => 'admin@fundthatflip.com'

  def send_signature_request_email(parties, targetEmail, link, document)
    @parties = parties
    @targetEmail = targetEmail
    @link = link

    mail(
      :to => targetEmail,
      :subject => document
    )
  end
end
