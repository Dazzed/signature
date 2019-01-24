require 'test_helper'

class Api::DocumentStatusControllerTest < ActionDispatch::IntegrationTest

  test "Document List" do
    get deals_url, params: {"client_deal_id"=>"_12345abcde", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}

    post documents_url, params: {"template_id"=>"45b50b15cae62dba5999ee13ba80107098c185d7", "client_deal_id"=>"_12345abcde", "signer_roles"=>{"0"=>"niraj.bothra@gmail.com", "1"=>"sameep.dev@gmail.com"}, "deal_attributes"=>{"cff33a_9"=>"Senior React JS Developer"}}

    get api_document_status_index_url, params: {"client_deal_id"=>"_12345abcde"}

    assert_response :success
  end


end
