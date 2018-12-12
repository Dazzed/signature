require 'test_helper'

class HellosignControllerTest < ActionDispatch::IntegrationTest
  test "HelloSign Callback" do

    get deals_url, params: {"client_deal_id"=>"_12345abcde", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    post documents_url, params: {"template_id"=>"45b50b15cae62dba5999ee13ba80107098c185d7", "client_deal_id"=>"_12345abcde", "signer_roles"=>{"0"=>"niraj.bothra@gmail.com", "1"=>"sameep.dev@gmail.com"}, "deal_attributes"=>{"cff33a_9"=>"Senior React JS Developer"}}
    sleep(10)
    
    post callbacks_hellosign_index_url, params: {"json" => "{\"event\": {\"event_type\": \"signature_request_signed\",\"event_metadata\": {\"signature_request_id\": \"1234\",\"related_signature_id\": \"5678\"}},\"signature_request\": {\"metadata\": {\"document_id\": \"" + Document.all.first.id + "\"}}}"}
    
    assert_response :success
  end

end
