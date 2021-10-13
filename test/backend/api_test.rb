require './test/test_helper.rb'

class PostControllerTest < Minitest::Test
  def test_should_be_able_to_get
    @path = '/api/v1/images/search'
    get @path
    assert last_response.ok?
    assert_equal @path, last_request.path_info
  end
end
