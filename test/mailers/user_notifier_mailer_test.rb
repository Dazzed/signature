require 'test_helper'

class UserNotifierMailerTest < ActionMailer::TestCase

  test "send_signature_request_email" do
    deal_params = {"client_deal_id"=>"_12345abcdef", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    deal = Deal.new(:client_deal_id => deal_params["client_deal_id"], :deal_attributes => deal_params.to_json)

    deal.save


    template_id = "45b50b15cae62dba5999ee13ba80107098c185d7"
    template = HellosignService::get_template_data(template_id)
    client_deal_id = deal_params["client_deal_id"]
    signer_roles = {"0"=>"niraj.bothra@gmail.com", "1"=>"sameep.dev@gmail.com"}
    signer_roles_pay = {"0"=>"true", "1"=>"true"}
    deal_attributes = {"cff33a_9"=>"Senior React JS Developer"}

    parties = HellosignService::get_parties(template, signer_roles, signer_roles_pay)

    deal = Deal.find_by(:client_deal_id => client_deal_id)
    # Create a new document in database
    new_document = deal.documents.create({
      :client_deal_id => deal.client_deal_id,
      :parties => parties,
      :template_id => template["template_id"],
      :document_title => template["title"],
      :deal_attributes => deal_attributes.to_h,
      :complete => false
    })

    sleep(10)
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
    email = UserNotifierMailer.email_signed_document("favicon.ico", Document.all.first.document_title, 'niraj.bothra@gmail.com')
 
    assert_emails 1 do
      email.deliver_now
    end
 
    assert_equal ['niraj.bothra@gmail.com'], email.to
    assert_equal Document.first.document_title, email.subject
  end



end
