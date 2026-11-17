module Assistant::ResponseLanguage
  def self.instructions(user)
    locale = user&.resolved_locale || I18n.default_locale
    "Response language: #{locale}. Write user-facing responses in this language unless the user explicitly requests another language. " \
      "Preserve user-provided names, tool names, protocol keys and JSON schemas."
  end
end
