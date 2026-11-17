# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Usage', type: :request do
  let(:family) { Family.create!(name: 'API Family', currency: 'USD', locale: 'en') }
  let(:user) { family.users.create!(email: 'usage-docs@example.com', password: 'password123') }
  let(:api_key) do
    key = ApiKey.generate_secure_key
    ApiKey.create!(user: user, name: 'API Docs Key', key: key, scopes: %w[read_write], source: 'web')
  end
  let(:'X-Api-Key') { api_key.plain_key }

  path '/api/v1/usage' do
    get 'Read API usage' do
      tags 'Usage'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      parameter name: :'Accept-Language', in: :header, type: :string, required: false,
                description: 'Preferred response language; a saved user locale takes precedence. Error codes remain unchanged.'

      response '200', 'usage retrieved' do
        schema type: :object, required: %w[api_key rate_limit], properties: {
          api_key: { type: :object }, rate_limit: { type: :object }
        }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:'X-Api-Key') { nil }
        run_test!
      end
    end
  end
end
