require "test_helper"

class SetupsControllerTest < ActionDispatch::IntegrationTest
  setup { User.destroy_all }

  test "show when the installation has no user" do
    get setup_path

    assert_response :success
  end

  test "create the installation user and sign in" do
    assert_difference -> { User.count }, 1 do
      post setup_path, params: {
        user: {
          email_address: "Owner@Example.com ",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "owner@example.com", User.sole.email_address
    assert cookies[:session_id]
  end

  test "invalid account details render setup" do
    assert_no_difference -> { User.count } do
      post setup_path, params: {
        user: {
          email_address: "",
          password: "password",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "setup is unavailable after an account exists" do
    User.create!(email_address: "owner@example.com", password: "password")

    get setup_path

    assert_redirected_to new_session_path
  end

  test "account creation is unavailable after an account exists" do
    User.create!(email_address: "owner@example.com", password: "password")

    assert_no_difference -> { User.count } do
      post setup_path, params: {
        user: {
          email_address: "another@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to new_session_path
  end

  test "protected pages redirect to setup when the installation has no user" do
    get root_path

    assert_redirected_to setup_path
  end
end
