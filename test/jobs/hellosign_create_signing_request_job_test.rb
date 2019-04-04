require 'test_helper'

class HellosignCreateSigningRequestJobTest < ActiveJob::TestCase
  test "Signing Request Sent" do
    deal_params = {"client_deal_id"=>"_12345abcdef", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    deal = Deal.new(:client_deal_id => deal_params["client_deal_id"], :deal_attributes => deal_params.to_json)

    deal.save


    template_id = "45b50b15cae62dba5999ee13ba80107098c185d7"
    template = SignatureService::get_template_data(template_id)
    client_deal_id = deal_params["client_deal_id"]
    signer_roles = {"0"=>"niraj.bothra@gmail.com", "1"=>"sameep.dev@gmail.com"}
    signer_roles_pay = {"0"=>"true", "1"=>"true"}
    deal_attributes = {"cff33a_9"=>"Senior React JS Developer"}

    parties = SignatureService::get_parties(template, signer_roles, signer_roles_pay)

    deal = Deal.find_by(:client_deal_id => client_deal_id)
    # Create a new document in database
    new_document = deal.documents.create({
      :client_deal_id => deal.client_deal_id,
      :parties => parties,
      :template_id => template["template_id"],
      :document_title => template["title"],
      :address => "",
      :deal_attributes => deal_attributes.to_h,
      :complete => false
    })



    HellosignCreateSigningRequestJob.perform_now(Document.first)
    assert !Document.first.parties[0]["signature_request_id"].nil?
  end
end
