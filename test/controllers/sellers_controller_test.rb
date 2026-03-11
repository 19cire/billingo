require "test_helper"

class SellersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get sellers_create_url
    assert_response :success
  end
end
