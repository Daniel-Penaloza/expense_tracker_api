# frozen_string_literal: true

require_relative '../config/sequel'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  # Ledger: the engine for store expenses
  class Ledger
    def record(expense)
      missing_key = check_keys(expense)
      unless missing_key.empty?
        message = "Invalid expense: `#{missing_key.join('')}` is required"
        return RecordResult.new(false, nil, message)
      end

      DB[:expenses].insert(expense)
      id = DB[:expenses].max(:id)
      RecordResult.new(true, id, nil)
    end

    def expenses_on(date)
      DB[:expenses].where(date:).all
    end

    def check_keys(expense)
      expense = expense.transform_keys { |k| k&.to_s }
      expected_keys = %w[payee amount date]
      missing_keys = expected_keys - expense.keys
      return missing_keys if missing_keys
    end

    def return_expense_xml(result)
      doc = Ox::Document.new  
      
      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      instruct[:standalone] = 'yes'
      doc << instruct

      payees = Ox::Element.new('payees')
      doc << payees

      result.each do |r|
        payee = Ox::Element.new('payee')
        payee << r[:payee]
        doc << payee

        amount = Ox::Element.new('amount')
        amount << r[:amount].to_s
        doc << amount

        date = Ox::Element.new('date')
        date << r[:date].to_s
        doc << date
      end
      return Ox.dump(doc)
    end
  end
end
