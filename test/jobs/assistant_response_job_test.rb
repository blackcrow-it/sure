require "test_helper"

class AssistantResponseJobTest < ActiveJob::TestCase
  test "worker uses the chat owner locale for responses and broadcasts" do
    message = chats(:one).messages.where(type: "UserMessage").first!
    message.chat.user.update!(locale: "vi")
    Current.reset
    ChatReservation.stubs(:while_chat_runs).yields
    message.expects(:request_response).with(assistant_message: nil) { I18n.locale == :vi }
    message.chat.expects(:hold_reservation).with { I18n.locale == :vi }

    I18n.with_locale(:en) do
      AssistantResponseJob.perform_now(message)
      assert_equal :en, I18n.locale
    end
  end
end
