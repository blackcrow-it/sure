# Writes user-supplied daily closes for a security no provider tracks. Rows land in the shared security_prices table,
# so they value every family holding the security, not just the caller's.
#
# All rows are validated before any is written, and the write is one upsert:
# a request either stores every close or none.
class Security::ManualPriceImport
  MAX_ROWS = 1000

  Result = Data.define(:currency, :created, :updated, :start_date, :end_date)

  class Invalid < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.map { |e| e[:message] }.join("; "))
    end
  end

  # `accounts` are the caller's accounts trading the security, or holding it
  # in a linked account. A security with no prices yet takes its currency from
  # their trades, or failing that their holdings.
  def initialize(security:, rows:, accounts:)
    @security = security
    @rows = rows
    @accounts = accounts
  end

  def import!
    raise Invalid.new([ error(nil, I18n.t("vietnamese_ui.prices.rows_required")) ]) if rows.empty?
    raise Invalid.new([ error(nil, I18n.t("vietnamese_ui.prices.too_many_rows", count: MAX_ROWS)) ]) if rows.size > MAX_ROWS

    parsed, errors = parse_rows

    # The unique key includes currency, so two first imports in different
    # currencies would not conflict. The security's row lock is held from the
    # eligibility and currency checks through the upsert, so a resolver that
    # assigns a provider, or another import, cannot slip in between.
    security.with_lock do
      raise Invalid.new([ error(nil, I18n.t("vietnamese_ui.prices.cash")) ]) if security.cash?
      raise Invalid.new([ error(nil, I18n.t("vietnamese_ui.prices.tracked")) ]) unless untracked?
      # Every bad row is reported at once: a row that parsed can still carry
      # the wrong currency beside one that did not parse.
      errors = (errors + currency_errors(parsed)).sort_by { |e| e[:index] || -1 }
      raise Invalid.new(errors) if errors.any?

      write(parsed)
    end
  end

  private
    attr_reader :security, :rows, :accounts

    ParsedRow = Data.define(:index, :date, :price, :currency)

    # Offline with no reason and no assigned provider means no provider ever
    # matched the ticker. Any other offline security is a listed one that is
    # down for now ("health_check_failed", "provider_disabled",
    # "resolution_pending"). The importer keeps non-provisional rows, so closes
    # written there would outlast the provider's own once it came back.
    def untracked?
      security.offline? && security.offline_reason.blank? && security.price_provider.blank?
    end

    def parse_rows
      errors = []
      seen_dates = {}

      parsed = rows.each_with_index.filter_map do |row, index|
        unless row.is_a?(Hash)
          errors << error(index, I18n.t("vietnamese_ui.prices.row"))
          next
        end

        date, date_error = parse_date(row["date"])
        price, price_error = parse_price(row["price"])
        currency = row["currency"].to_s.strip.upcase
        currency_error = I18n.t("vietnamese_ui.prices.currency") unless Money::Currency.all.key?(currency.downcase)

        message = date_error || price_error || currency_error
        if message.nil? && seen_dates.key?(date)
          message = I18n.t("vietnamese_ui.prices.duplicate_date")
        end

        if message
          errors << error(index, message)
          next
        end

        seen_dates[date] = true
        ParsedRow.new(index:, date:, price:, currency:)
      end

      [ parsed, errors ]
    end

    # Calendar dates only: Date.iso8601 also takes week ("2026-W10-1"),
    # ordinal ("2026-070") and basic ("20260301") forms.
    def parse_date(value)
      raise ArgumentError unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      date = Date.iso8601(value.to_s)
      return [ nil, I18n.t("vietnamese_ui.prices.future_date") ] if date > Date.current

      [ date, nil ]
    rescue ArgumentError
      [ nil, I18n.t("vietnamese_ui.prices.date") ]
    end

    def parse_price(value)
      price = BigDecimal(value.to_s)
      return [ nil, I18n.t("vietnamese_ui.prices.positive") ] unless price.positive?
      return [ nil, I18n.t("vietnamese_ui.prices.precision") ] unless price.round(4) == price
      return [ nil, I18n.t("vietnamese_ui.prices.too_large") ] if price >= 10**15

      [ price, nil ]
    rescue ArgumentError, TypeError
      [ nil, I18n.t("vietnamese_ui.prices.number") ]
    end

    def currency_errors(parsed)
      return [] if parsed.empty?

      allowed = allowed_currencies
      return [ error(nil, allowed[:error]) ] if allowed[:error]

      batch_currency = parsed.first.currency
      parsed.filter_map do |row|
        if allowed[:currencies].exclude?(row.currency)
          error(row.index, allowed[:message])
        elsif row.currency != batch_currency
          error(row.index, I18n.t("vietnamese_ui.prices.same_currency"))
        end
      end
    end

    # A security's existing prices fix its currency. Without any, the caller's
    # trades decide, then their holdings. Valuation reads a stored price for a
    # date without choosing a currency, so a second currency is never added.
    def allowed_currencies
      existing = security.prices.distinct.order(:currency).pluck(:currency)
      if existing.any?
        noun = existing.one? ? I18n.t("vietnamese_ui.prices.currency_singular") : I18n.t("vietnamese_ui.prices.currency_plural")
        return { currencies: existing, message: I18n.t("vietnamese_ui.prices.existing_currency", currencies: existing.to_sentence(two_words_connector: I18n.t("vietnamese_ui.prices.or"), last_word_connector: I18n.t("vietnamese_ui.prices.or")), noun: noun) }
      end

      currencies, source = position_currencies
      if currencies.empty?
        return { error: I18n.t("vietnamese_ui.prices.no_currency") }
      end
      if currencies.many?
        return { error: I18n.t("vietnamese_ui.prices.multiple_currencies", source: I18n.t("vietnamese_ui.prices.#{source}"), currencies: currencies.join(", ")) }
      end

      { currencies: currencies, message: I18n.t("vietnamese_ui.prices.position_currency", currency: currencies.first, source: I18n.t("vietnamese_ui.prices.#{source}")) }
    end

    def position_currencies
      account_ids = accounts.select(:id)
      from_trades = Trade.joins(:entry).where(security: security, entries: { account_id: account_ids })
        .where.not(currency: nil).distinct.order(:currency).pluck(:currency)
      return [ from_trades, "trades" ] if from_trades.any?

      from_holdings = Holding.where(security: security, account_id: account_ids)
        .where.not(currency: nil).distinct.order(:currency).pluck(:currency)
      [ from_holdings, "holdings" ]
    end

    def write(parsed)
      currency = parsed.first.currency
      dates = parsed.map(&:date)

      # xmax is 0 only on a row this statement inserted, so the counts hold
      # even when another request writes the same dates concurrently.
      inserted = Security::Price.upsert_all(
        parsed.map { |row| { security_id: security.id, date: row.date, price: row.price, currency: currency, provisional: false } },
        unique_by: %i[security_id date currency],
        update_only: %i[price provisional],
        returning: Arel.sql("(xmax = 0) AS inserted")
      ).rows.flatten
      created = inserted.count(true)

      Result.new(currency:, created:, updated: inserted.size - created, start_date: dates.min, end_date: dates.max)
    end

    def error(index, message)
      { index: index, message: message }
    end
end
