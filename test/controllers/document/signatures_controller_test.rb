require 'test_helper'

class SignaturesControllerTest < ActionDispatch::IntegrationTest
  test "Create new signature URL" do
    get new_document_signature_url, params: {"document_id"=>Document.first.id, "uuid"=>Document.first.parties[0]["uuid"], "order"=>"0"}
    assert_response :success
  end
  test "Create new signature URL - Fail" do
    get new_document_signature_url, params: {}
    
    assert_response :success
    assert_select "p", 'Looks like you have reached here incorrectly.'
  end
end
