class ApplyAllRulesJob < ApplicationJob
  queue_as :medium_priority

  retry_on Rule::Runner::LockBusy, wait: 30.seconds, attempts: 20

  def perform(family, execution_type: "manual")
    I18n.with_locale(family&.locale.presence || I18n.default_locale) do
      Rule::Runner.new(
        family,
        rules: family.rules,
        execution_type: execution_type,
        ignore_attribute_locks: true
      ).run
    end
  end
end
