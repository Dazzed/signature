class UserNotifierMailer < ApplicationMailer
  default :from => 'admin@fundthatflip.com'

  def send_signature_request_email(parties, target_email, link, document)
    @parties = parties
    @target_email = target_email
    @link = link

    mail(
      :to => target_email,
      :subject => document
    )
  end
end
