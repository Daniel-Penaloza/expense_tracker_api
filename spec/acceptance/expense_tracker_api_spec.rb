# frozen_string_literal: true

require 'rack/test'
require 'json'
require_relative '../../app/api'
require 'ox'

# ExpenseTracker: The module of the application
module ExpenseTracker
  RSpec.describe 'Expense Tracker API', :db do
    include Rack::Test::Methods

    def app
      ExpenseTracker::API.new
    end

    def post_expense(expense, content_type)
      if content_type.eql?('json')
        post '/expenses', JSON.generate(expense), { 'CONTENT_TYPE' => 'application/json' }
        response_status(expense, last_response, content_type)
      else content_type.eql?('xml')
        post '/expenses', expense, { 'CONTENT_TYPE' => 'text/xml' }
        response_status(expense, last_response, content_type)
      end
    end

    def response_status(expense, response, content_type)
      expect(response.status).to eq(200)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include('expense_id' => a_kind_of(Integer))
      
      if content_type.eql?('json')
        expense.merge('id' => parsed['expense_id'])
      else
        expense = Ox.load(expense, mode: :hash)
        expense.merge('id' => parsed['expense_id']) 
      end
    end

    context 'records submitted expenses' do
      it 'as JSON' do
        coffee_json = post_expense( { 'payee' => 'Starbucks', 'amount' => 5.75, 'date' => '2017-06-10' }, 'json')
        zoo_json = post_expense( { 'payee' => 'Zoo', 'amount' => 15.75, 'date' => '2017-06-10' }, 'json')
        groceries_json = post_expense( { 'payee' => 'Whole Foods', 'amount' => 95.20, 'date' => '2017-06-11' }, 'json')
        
        header "Accept", "application/json"
        get '/expenses/2017-06-10'
        
        expect(last_response.status).to eq(200)
        expenses = JSON.parse(last_response.body)
        expect(expenses).to contain_exactly(coffee_json, zoo_json)
      end

      it 'as XML' do
        zoo = post_expense('<payee>Zoo</payee><amount>15.75</amount><date>2017-06-10</date>', 'xml')
        coffee = post_expense('<payee>Starbucks</payee><amount>5.75</amount><date>2017-06-10</date>', 'xml')
        groceries = post_expense('<payee>Whole Foods</payee><amount>95.20</amount><date>2017-06-11</date>', 'xml')
        
        header "Accept", "text/xml"
        get '/expenses/2017-06-10'
        
        expenses = last_response.body
        expect(expenses).to include("Starbucks", "Zoo")
      end
    end
  end
end
