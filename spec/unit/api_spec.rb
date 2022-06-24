# frozen_string_literal: true

require_relative '../../app/api'
require 'rack/test'

# ExpenseTracker: The module wrapper of the app
module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger:)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }
    let(:expense) { { 'some' => 'data' } }

    def parsed_json(response, data)
      parsed = JSON.parse(response)
      expect(parsed).to include(data)
    end

    describe 'POST /expenses' do
      context 'when the expense is succesfully recorded' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense), { 'CONTENT_TYPE' => 'application/json' }
          parsed_json(last_response.body, { 'expense_id' => 417 })
        end

        it 'responds with a 200(OK)' do
          post '/expenses', JSON.generate(expense), { 'CONTENT_TYPE' => 'application/json' }
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense), { 'CONTENT_TYPE' => 'application/json' }
          parsed_json(last_response.body, { 'error' => 'Expense incomplete' })
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense), { 'CONTENT_TYPE' => 'application/json' }
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /expenses/:date' do
      def expenses_by_date(date)
        get "/expenses/#{date}"
        expect(last_response.status).to eq(200)
      end

      context 'when expenses exist on the given date' do
        let(:expense_one) { { 'payee' => 'Starbucks', 'amount' => 5.75, 'date' => '2017-06-10' } }
        let(:expense_two) { { 'payee' => 'Zoo', 'amount' => 19.20, 'date' => '2017-06-10' } }

        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-10')
            .and_return([expense_one, expense_two])
        end

        it 'returns the expense records as JSON' do
          expenses_by_date('2017-06-10')

          parsed = JSON.parse(last_response.body)
          expect(parsed).to contain_exactly(expense_one, expense_two)
        end

        it 'responds with a 200(OK)' do
          expenses_by_date('2017-06-10')
        end
      end

      context 'when tehre are no expenses on the given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-11')
            .and_return([])
        end

        it 'returns and empty array as JSON' do
          get '/expenses/2017-06-11'
          expect(last_response.body).to eq('[]')
        end

        it 'responds with a 200 (OK)' do
          expenses_by_date('2017-06-11')
        end
      end
    end
  end
end
