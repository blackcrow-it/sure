class Insight::BodyWriter
  def write(generated_insight, locale: I18n.locale)
    I18n.t(
      "insights.templates.#{generated_insight.template_key}",
      **generated_insight.facts.symbolize_keys,
      locale: locale
    )
  end
end
