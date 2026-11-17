class ImportJob < ApplicationJob
  queue_as :high_priority

  def perform(import)
    I18n.with_locale(import.family&.locale.presence || I18n.default_locale) do
      import.publish
    end
  end
end
