class UserNotifierMailer < ApplicationMailer
  default :from => 'admin@fundthatflips.com'

  def send_signature_request_email(parties, targetEmail, link)
    @parties = parties
    @targetEmail = targetEmail
    @link = link
    p "AM HERE"
    p parties, targetEmail, link
    mail(
      :to => targetEmail,
      :subject => 'Document Signature Request'
    )
  end
end
