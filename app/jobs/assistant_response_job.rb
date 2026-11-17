class AssistantResponseJob < ApplicationJob
  queue_as :ai_high_priority

  def perform(message, assistant_message = nil)
    I18n.with_locale(message.chat.user.resolved_locale) do
      begin
        ChatReservation.while_chat_runs { message.request_response(assistant_message: assistant_message) }
      ensure
        # Hold background AI jobs back so a reply to this answer runs next.
        message.chat.hold_reservation
      end
    end
  end
end
