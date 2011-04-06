require 'test_helper'

class MobminControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show_databases" do
    get :show_databases
    assert_response :success
  end

  test "should get show_tables" do
    get :show_tables
    assert_response :success
  end

  test "should get table_info" do
    get :table_info
    assert_response :success
  end

end
