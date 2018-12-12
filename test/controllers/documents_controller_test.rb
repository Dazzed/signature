require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  test "New Document" do
    get deals_url, params: {"client_deal_id"=>"_12345abcde", "IsAvailable"=>"Full Time available", "Actual Job Description"=>"Senior React JS Developer", "Validity date"=>"Upto April 2019", "Manager"=>"niraj.bothra@gmail.com", "Client"=>"sameep.dev@gmail.com", "deal_amount"=>"1000", "deal_title"=>"First Deal", "deal_currency"=>"USD"}
    get new_document_url, params: {"template_id"=>"53cf2cf9db129534a713f338826a7dd7634da0c7", "client_deal_id"=>"_12345abcde"}
    assert_response :success
    assert_select "h5", 'Signer Roles'
  end
  test "New Document - Error" do
    get new_document_url, params: {}
    assert_response :success
    assert_select "p", 'Looks like you have reached here incorrectly.'
  end

  test "Create Document" do
    post documents_url, params: {"template_id"=>"45b50b15cae62dba5999ee13ba80107098c185d7", "client_deal_id"=>"_12345abcde", "signer_roles"=>{"0"=>"niraj.bothra@gmail.com", "1"=>"sameep.dev@gmail.com"}, "deal_attributes"=>{"cff33a_9"=>"Senior React JS Developer"}}
    assert_response :redirect
    assert_redirected_to deals_url + "?client_deal_id=_12345abcde&show_status=true"
  end

  test "Create Document - Fail" do
    post documents_url, params: {}
    assert_response :success
    assert_select "p", 'Looks like you have reached here incorrectly.'
  end

end
