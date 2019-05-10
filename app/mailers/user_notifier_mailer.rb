class UserNotifierMailer < ApplicationMailer
  default :from => 'Fund That Flip <admin@fundthatflip.com>'

  def send_signature_request_email(parties, target_email, link, document)
    @parties = parties
    @target_email = target_email
    @link = link

    # UNCOMMENT ME AFTER
    # mail(
    #   :to => target_email,
    #   :subject => document.address + " - Term Sheet"
    # )

    # DELETE ME AFTER
    mail(
      :to => target_email,
      :subject => " - Term Sheet"
    )
  end

  def email_signed_document(file, document, email)
    @file = file 
    attachments["#{file}"] = File.read("public/" + file)
    mail(
      :to => email,
      :subject => document.address + " - Term Sheet"
    )
  end

end
