# frozen_string_literal: true

# Tests SSO provider configuration by validating discovery endpoints
class SsoProviderTester
  extend SslConfigurable

  attr_reader :provider, :result

  Result = Struct.new(:success?, :message, :details, keyword_init: true)

  def initialize(provider)
    @provider = provider
    @result = nil
  end

  def test!
    @result = case provider.strategy
    when "openid_connect"
      test_oidc_discovery
    when "google_oauth2"
      test_google_oauth
    when "github"
      test_github_oauth
    when "saml"
      test_saml_metadata
    else
      Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.unknown_strategy", strategy: provider.strategy), details: {})
    end
  end

  private

    def test_oidc_discovery
      return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.issuer_required"), details: {}) if provider.issuer.blank?

      discovery_url = build_discovery_url(provider.issuer)

      begin
        response = faraday_client.get(discovery_url) do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5
        end

        unless response.success?
          return Result.new(
            success?: false,
            message: I18n.t("vietnamese_ui.sso_test.discovery_status", status: response.status),
            details: { url: discovery_url, status: response.status }
          )
        end

        discovery = JSON.parse(response.body)

        # Validate required OIDC fields
        required_fields = %w[issuer authorization_endpoint token_endpoint]
        missing = required_fields.select { |f| discovery[f].blank? }

        if missing.any?
          return Result.new(
            success?: false,
            message: I18n.t("vietnamese_ui.sso_test.missing_fields", fields: missing.join(", ")),
            details: { url: discovery_url, missing_fields: missing }
          )
        end

        # Check if issuer matches exactly. OIDC discovery requires the configured
        # issuer string to be identical to the issuer returned by the provider.
        if discovery["issuer"] != provider.issuer
          hint = trailing_slash_hint(provider.issuer, discovery["issuer"])

          return Result.new(
            success?: false,
            message: [ I18n.t("vietnamese_ui.sso_test.issuer_mismatch", expected: provider.issuer, actual: discovery["issuer"]), hint ].compact.join(". "),
            details: { expected: provider.issuer, actual: discovery["issuer"] }
          )
        end

        Result.new(
          success?: true,
          message: I18n.t("vietnamese_ui.sso_test.oidc_valid"),
          details: {
            issuer: discovery["issuer"],
            authorization_endpoint: discovery["authorization_endpoint"],
            token_endpoint: discovery["token_endpoint"],
            end_session_endpoint: discovery["end_session_endpoint"],
            scopes_supported: discovery["scopes_supported"]
          }
        )

      rescue Faraday::TimeoutError
        Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.timeout"), details: { url: discovery_url })
      rescue Faraday::ConnectionFailed => e
        Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.connection_failed", message: e.message), details: { url: discovery_url })
      rescue JSON::ParserError
        Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.json_invalid"), details: { url: discovery_url })
      rescue StandardError => e
        Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.error", message: e.message), details: { url: discovery_url })
      end
    end

    def test_google_oauth
      # Google OAuth doesn't require discovery validation - just check credentials present
      if provider.client_id.blank?
        return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.client_id"), details: {})
      end

      if provider.client_secret.blank?
        return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.client_secret"), details: {})
      end

      Result.new(
        success?: true,
        message: I18n.t("vietnamese_ui.sso_test.google_valid"),
        details: {
          note: "Full validation occurs during actual authentication"
        }
      )
    end

    def test_github_oauth
      # GitHub OAuth doesn't require discovery validation - just check credentials present
      if provider.client_id.blank?
        return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.client_id"), details: {})
      end

      if provider.client_secret.blank?
        return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.client_secret"), details: {})
      end

      Result.new(
        success?: true,
        message: I18n.t("vietnamese_ui.sso_test.github_valid"),
        details: {
          note: "Full validation occurs during actual authentication"
        }
      )
    end

    def test_saml_metadata
      # SAML testing - check for IdP metadata or SSO URL
      if provider.settings&.dig("idp_metadata_url").blank? &&
         provider.settings&.dig("idp_sso_url").blank?
        return Result.new(
          success?: false,
          message: I18n.t("vietnamese_ui.sso_test.saml_url"),
          details: {}
        )
      end

      # If metadata URL is provided, try to fetch it
      metadata_url = provider.settings&.dig("idp_metadata_url")
      if metadata_url.present?
        begin
          response = faraday_client.get(metadata_url) do |req|
            req.options.timeout = 10
            req.options.open_timeout = 5
          end

          unless response.success?
            return Result.new(
              success?: false,
              message: I18n.t("vietnamese_ui.sso_test.metadata_status", status: response.status),
              details: { url: metadata_url, status: response.status }
            )
          end

          # Basic XML validation
          unless response.body.include?("<") && response.body.include?("EntityDescriptor")
            return Result.new(
              success?: false,
              message: I18n.t("vietnamese_ui.sso_test.saml_invalid"),
              details: { url: metadata_url }
            )
          end

          return Result.new(
            success?: true,
            message: I18n.t("vietnamese_ui.sso_test.saml_fetched"),
            details: { url: metadata_url }
          )
        rescue Faraday::TimeoutError
          return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.timeout"), details: { url: metadata_url })
        rescue Faraday::ConnectionFailed => e
          return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.connection_failed", message: e.message), details: { url: metadata_url })
        rescue StandardError => e
          return Result.new(success?: false, message: I18n.t("vietnamese_ui.sso_test.error", message: e.message), details: { url: metadata_url })
        end
      end

      Result.new(
        success?: true,
        message: I18n.t("vietnamese_ui.sso_test.saml_valid"),
        details: {
          note: "Full validation occurs during actual authentication"
        }
      )
    end

    def build_discovery_url(issuer)
      if issuer.end_with?("/")
        "#{issuer}.well-known/openid-configuration"
      else
        "#{issuer}/.well-known/openid-configuration"
      end
    end

    def faraday_client
      @faraday_client ||= Faraday.new(ssl: self.class.faraday_ssl_options)
    end

    def trailing_slash_hint(expected, actual)
      return unless expected.to_s.chomp("/") == actual.to_s.chomp("/")

      I18n.t("vietnamese_ui.sso_test.trailing_slash")
    end
end
