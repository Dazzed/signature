require 'test_helper'

class UserNotifierMailerTest < ActionMailer::TestCase

  test "send_signature_request_email" do
    # Create the email and store it for further assertions
    email = UserNotifierMailer.send_signature_request_email(Document.first.parties, 'niraj.bothra@gmail.com', ENV["EMAIL_SIGNING_URL"] + "?document_id=" + Document.first.id + "&order=0&&uuid=" + Document.first.parties[0]["uuid"], Document.first.document_title)
 
    assert_emails 1 do
      email.deliver_now
    end
 
    assert_equal ['niraj.bothra@gmail.com'], email.to
    assert_equal Document.first.document_title, email.subject
  end

  test "email_signed_document" do
    # Create the email and store it for further assertions
    email = UserNotifierMailer.email_signed_document("favicon.ico", Document.first.document_title, 'niraj.bothra@gmail.com')
 
    assert_emails 1 do
      email.deliver_now
    end
 
    assert_equal ['niraj.bothra@gmail.com'], email.to
    assert_equal Document.first.document_title, email.subject
  end



end
