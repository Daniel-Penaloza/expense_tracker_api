# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative 'ledger'
require 'byebug'
require 'ox'

module ExpenseTracker
  # Class API: The main class for all our app.
  class API < Sinatra::Base
    
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post '/expenses' do
      if request.content_type == 'application/json'
        expense = JSON.parse(request.body.read)
        result = @ledger.record(expense)
      else
        expense = Ox.load(request.body.read, mode: :hash)
        result = @ledger.record(expense)
      end

      if result.success?
        JSON.generate('expense_id' => result.expense_id)
      else
        status 422
        JSON.generate('error' => result.error_message)
      end
    end

    get '/expenses/:date', :provides => ['json', 'xml'] do
      if headers['Content-Type'].include?('application/json')
        result = @ledger.expenses_on(params[:date])
        if result.nil?
          JSON.generate([])
        else
          JSON.generate(result)
        end
      else
        result = @ledger.expenses_on(params[:date])
        if result.nil?
          ""
        else
          @ledger.return_expense_xml(result)
        end
      end
    end
  end
end
