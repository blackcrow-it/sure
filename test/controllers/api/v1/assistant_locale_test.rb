require "test_helper"

class Api::V1::AssistantLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.update!(ai_enabled: true)
    @user.family.update!(locale: "en")
    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(user: @user, name: "Assistant locale", scopes: %w[read_write],
                             source: "web", display_key: "ai_locale_#{SecureRandom.hex(16)}")
    ChatReservation.stubs(:while_chat_runs).yields
    Chat.any_instance.stubs(:hold_reservation)
  end

  %w[builtin external].each do |assistant_type|
    [ nil, "en" ].each do |saved_locale|
      expected_locale = saved_locale || "vi"
      test "#{assistant_type} uses #{expected_locale} after vi-VN API request with saved locale #{saved_locale.inspect}" do
        @user.update!(locale: saved_locale)
        Family.any_instance.stubs(:effective_assistant_type).returns(assistant_type)
        preferences = @user.family.attributes.slice("currency", "timezone", "locale")

        post "/api/v1/chats", params: { title: "Language test", message: "Keep this name unchanged", model: "test-model" },
             headers: api_headers(@api_key).merge("Accept-Language" => "vi-VN,vi;q=0.9,en;q=0.8"), as: :json

        assert_response :created
        assert_equal expected_locale, @user.reload.locale
        assert_equal preferences, @user.family.reload.attributes.slice("currency", "timezone", "locale")
        chat = @user.chats.find_by!(title: "Language test")
        message = chat.messages.find_by!(type: "UserMessage")
        # Re-fetch in the worker after clearing request state: do not rely on
        # Current or the locale that ActiveJob captured at enqueue time.
        Current.reset
        message = UserMessage.find(message.id)
        expect_response_language(assistant_type, expected_locale, message)

        I18n.with_locale(:en) do
          AssistantResponseJob.perform_now(message)
          assert_equal :en, I18n.locale
        end
        assert_nil chat.reload.error
      end
    end
  end

  private
    def expect_response_language(assistant_type, locale, message)
      if assistant_type == "builtin"
        llm = mock("LLM provider")
        Assistant::Builtin.any_instance.stubs(:get_model_provider).with("test-model").returns(llm)
        responder = mock("responder")
        responder.stubs(:on)
        responder.expects(:respond).with(previous_response_id: nil)
        Assistant::Responder.expects(:new).with do |options|
          instructions = options[:instructions]
          assert instructions.start_with?(Assistant::Configurable::STATIC_INSTRUCTIONS)
          assert_includes instructions, "Response language: #{locale}"
          assert_equal locale.to_sym, I18n.locale
          options[:llm] == llm && options[:message] == message
        end.returns(responder)
      else
        Assistant::External.stubs(:configured?).returns(true)
        Assistant::External.stubs(:allowed_user?).returns(true)
        client = mock("external client")
        Assistant::External::Client.stubs(:new).returns(client)
        client.expects(:chat).with do |options|
          assert_equal "system", options[:messages].first[:role]
          assert_includes options[:messages].first[:content], "Response language: #{locale}"
          assert_equal "Keep this name unchanged", options[:messages].last[:content]
          assert_equal locale.to_sym, I18n.locale
          true
        end.yields("Reply").returns("test-model")
      end
    end
end
