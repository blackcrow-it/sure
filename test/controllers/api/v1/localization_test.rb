require "test_helper"

class Api::V1::LocalizationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @user.api_keys.active.destroy_all
    @api_key = ApiKey.create!(user: @user, name: "Localization", scopes: %w[read_write],
                             source: "web", display_key: "locale_#{SecureRandom.hex(16)}")
    @user.family.update!(locale: "en")
  end

  # These failures exercise real actions, including validation and rescue paths,
  # without mutating financial data or making external provider calls.
  CASES = [
    [ :get, "/api/v1/transfers", { account_id: "invalid" }, 422, "uuid", { field: "account_id" } ],
    [ :get, "/api/v1/rejected_transfers", { account_id: "invalid" }, 422, "uuid", { field: "account_id" } ],
    [ :get, "/api/v1/securities", { offline: "invalid" }, 422, "boolean", { field: "offline" } ],
    [ :get, "/api/v1/security_prices", { provisional: "invalid" }, 422, "boolean", { field: "provisional" } ],
    [ :get, "/api/v1/accounts/00000000-0000-0000-0000-000000000000", {}, 404, "account_not_found", {} ],
    [ :get, "/api/v1/categories/00000000-0000-0000-0000-000000000000", {}, 404, "category_not_found", {} ],
    [ :get, "/api/v1/holdings/00000000-0000-0000-0000-000000000000", {}, 404, "holding_not_found", {} ],
    [ :post, "/api/v1/account_statements", {}, 422, "statement_file_required", {} ],
    [ :get, "/api/v1/account_statements", { account_id: "invalid" }, 422, "uuid", { field: "account_id" } ],
    [ :get, "/api/v1/balances", { account_id: "invalid" }, 422, "uuid", { field: "account_id" } ],
    [ :get, "/api/v1/budget_categories", { budget_id: "invalid" }, 422, "uuid", { field: "budget_id" } ],
    [ :post, "/api/v1/family_exports", { unsupported: true }, 422, "export_parameters", {} ],
    [ :post, "/api/v1/imports", { type: "MonarchImport" }, 422, "monarch_web", {} ],
    [ :post, "/api/v1/merchants", {}, 422, "csv_required", {} ],
    [ :get, "/api/v1/recurring_transactions", { account_id: "invalid" }, 422, "uuid", { field: "account_id" } ],
    [ :get, "/api/v1/rules", { active: "invalid" }, 422, "active_values", {} ],
    [ :get, "/api/v1/rule_runs", { rule_id: "invalid" }, 422, "uuid", { field: "rule_id" } ],
    [ :get, "/api/v1/spending_vs_normal", { start_date: "invalid" }, 422, "period_invalid", {} ],
    [ :post, "/api/v1/trades", { trade: { amount: 1 } }, 422, "account_id_required", {} ],
    [ :post, "/api/v1/transactions", { transaction: { amount: 1 } }, 422, "account_id_required", {} ],
    [ :post, "/api/v1/valuations", { valuation: { amount: 1 } }, 422, "account_id_required", {} ]
  ].freeze

  CASES.each do |verb, path, parameters, status, key, interpolation|
    %w[vi en].each do |locale|
      test "#{verb} #{path} #{key} renders #{locale} with stable response structure" do
        @user.update!(locale: locale)
        headers = api_headers(@api_key).merge("Accept-Language" => locale == "vi" ? "en" : "vi-VN")

        public_send(verb, path, params: parameters, headers: headers, as: :json)

        assert_response status
        body = response.parsed_body
        assert body["error"].present?
        assert_equal I18n.t("vietnamese_ui.api.#{key}", locale: locale, **interpolation), body["message"]
        assert_equal locale, @user.reload.locale
      end
    end
  end

  test "unauthenticated Vietnamese request retains machine readable unauthorized code" do
    get "/api/v1/accounts", headers: { "Accept-Language" => "vi-VN" }

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["error"]
    assert_equal I18n.t("vietnamese_ui.api.credentials_invalid", locale: :vi), response.parsed_body["message"]
  end

  test "unsupported browser language falls back to English for an unset user" do
    @user.update!(locale: nil)
    get "/api/v1/accounts/00000000-0000-0000-0000-000000000000",
        headers: api_headers(@api_key).merge("Accept-Language" => "zz-ZZ")

    assert_response :not_found
    assert_equal "Account not found", response.parsed_body["message"]
  end

  {
    "en" => "This action requires the 'write' scope",
    "vi" => "Thao tác này yêu cầu phạm vi quyền 'write'"
  }.each do |locale, expected_message|
    test "read only key returns a translated permission error in #{locale}" do
      @user.update!(locale: locale)
      @api_key.update!(scopes: %w[read])
      post "/api/v1/transactions", params: { transaction: { amount: 1 } }, headers: api_headers(@api_key), as: :json

      assert_response :forbidden
      assert_equal "insufficient_scope", response.parsed_body["error"]
      assert_equal expected_message, response.parsed_body["message"]
      assert_not_includes response.body.downcase, "translation missing"
    end
  end

  test "family language is used when user and browser preferences are absent" do
    @user.update!(locale: nil)
    @user.family.update!(locale: "vi")
    get "/api/v1/accounts/00000000-0000-0000-0000-000000000000", headers: api_headers(@api_key)

    assert_response :not_found
    assert_equal I18n.t("vietnamese_ui.api.account_not_found", locale: :vi), response.parsed_body["message"]
  end
  %w[vi en].each do |locale|
    test "SSO exchange missing code is localized in #{locale}" do
      post "/api/v1/auth/sso_exchange", headers: { "Accept-Language" => locale }, as: :json

      assert_response :unauthorized
      assert_equal "invalid_or_expired_code", response.parsed_body["error"]
      assert_equal I18n.t("vietnamese_ui.api.authorization_code_required", locale: locale), response.parsed_body["message"]
    end

    test "preview and hosted push guards are localized in #{locale}" do
      @user.update!(locale: locale, preferences: @user.preferences.merge("preview_features_enabled" => false))
      get "/api/v1/insights", headers: api_headers(@api_key)
      assert_response :forbidden
      assert_equal "feature_disabled", response.parsed_body["error"]
      assert_equal I18n.t("vietnamese_ui.api.preview_disabled", locale: locale), response.parsed_body["message"]

      Apns::Client.stubs(:hosted?).returns(false)
      post "/api/v1/push_subscriptions", headers: api_headers(@api_key), as: :json
      assert_response :forbidden
      assert_equal I18n.t("vietnamese_ui.api.push_hosted_only", locale: locale), response.parsed_body["message"]
    end

    test "reset queue response is localized in #{locale}" do
      @user.update!(locale: locale)
      FamilyResetJob.stubs(:perform_later).returns(OpenStruct.new(job_id: "localized-reset"))

      post "/api/v1/users/reset", headers: api_headers(@api_key), as: :json

      assert_response :success
      assert_equal "queued", response.parsed_body["status"]
      assert_equal I18n.t("vietnamese_ui.api.reset_started", locale: locale), response.parsed_body["message"]
    end

    test "retry response is localized in #{locale}" do
      @user.update!(locale: locale, ai_enabled: true)
      chat = @user.chats.create!(title: "Language test")
      chat.messages.create!(type: "AssistantMessage", content: "Previous answer", ai_model: "test")

      post "/api/v1/chats/#{chat.id}/messages/retry", headers: api_headers(@api_key), as: :json

      assert_response :accepted
      assert response.parsed_body["message_id"].present?
      assert_equal I18n.t("vietnamese_ui.api.retry_started", locale: locale), response.parsed_body["message"]
    end
  end

  %w[vi en].each do |locale|
    test "provider and sync failures are localized in #{locale}" do
      @user.update!(locale: locale)
      ProviderConnectionStatus.stubs(:for_family).raises(StandardError, "unavailable")
      get "/api/v1/provider_connections", headers: api_headers(@api_key)
      assert_response :internal_server_error
      assert_equal I18n.t("vietnamese_ui.api.unexpected_error", locale: locale), response.parsed_body["message"]

      Family.any_instance.stubs(:sync_later).raises(StandardError, "unavailable")
      post "/api/v1/sync", headers: api_headers(@api_key), as: :json
      assert_response :internal_server_error
      assert_equal "internal_server_error", response.parsed_body["error"]
      assert_equal I18n.t("vietnamese_ui.api.unexpected_error", locale: locale), response.parsed_body["message"]
    end

    test "recurring transaction create update and delete messages use #{locale}" do
      @user.update!(locale: locale)
      post "/api/v1/recurring_transactions", params: { recurring_transaction: { name: "Invalid" } },
           headers: api_headers(@api_key), as: :json
      assert_response :unprocessable_entity
      assert_equal I18n.t("vietnamese_ui.api.recurring_create_failed", locale: locale), response.parsed_body["message"]

      recurring = recurring_transactions(:netflix_subscription)
      patch "/api/v1/recurring_transactions/#{recurring.id}", params: { recurring_transaction: { expected_day_of_month: 99 } },
            headers: api_headers(@api_key), as: :json
      assert_response :unprocessable_entity
      assert_equal I18n.t("vietnamese_ui.api.recurring_update_failed", locale: locale), response.parsed_body["message"]

      delete "/api/v1/recurring_transactions/#{recurring.id}", headers: api_headers(@api_key), as: :json
      assert_response :success
      assert_equal I18n.t("vietnamese_ui.api.recurring_deleted", locale: locale), response.parsed_body["message"]
    end

    test "import session validation and missing chunk content use #{locale}" do
      @user.update!(locale: locale)
      post "/api/v1/import_sessions", params: { type: "TransactionImport" }, headers: api_headers(@api_key), as: :json
      assert_response :unprocessable_entity
      assert_equal I18n.t("vietnamese_ui.imports.session_create_failed", locale: locale), response.parsed_body["message"]

      session = ImportSession.create_or_find_for!(family: @user.family, import_type: "SureImport", client_session_id: nil, expected_chunks: 1)
      post "/api/v1/import_sessions/#{session.id}/chunks", params: { sequence: 1 }, headers: api_headers(@api_key), as: :json
      assert_response :unprocessable_entity
      assert_equal I18n.t("vietnamese_ui.api.ndjson_required", locale: locale), response.parsed_body["message"]
    end
  end

end
