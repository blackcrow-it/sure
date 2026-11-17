class ImportSessionJob < ApplicationJob
  queue_as :high_priority

  def perform(import_session)
    raise ArgumentError, "ImportSessionJob requires an import_session" if import_session.nil?

    I18n.with_locale(import_session.family&.locale.presence || I18n.default_locale) do
      Rails.logger.info("ImportSessionJob started import_session_id=#{import_session.id}")
      import_session.publish
      import_session.reload
      Rails.logger.info("ImportSessionJob finished import_session_id=#{import_session.id} status=#{import_session.status}")
    end
  end
end
