# frozen_string_literal: true

require_relative '../../../app/ledger'
require_relative '../../../config/sequel'
require_relative '../../support/db'

# ExpenseTracker: The main module wrapper of the API
module ExpenseTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    let(:ledger) { Ledger.new }
    let(:expense) do
      {
        'payee' => 'Starbucks',
        'amount' => 5.75,
        'date' => '2017-06-10'
      }
    end

    describe '#record' do
      context 'with a valid expense' do
        it 'successfully saves the expense in the DB' do
          result = ledger.record(expense)

          expect(result).to be_success
          expect(DB[:expenses].all).to match [a_hash_including(
            id: result.expense_id,
            payee: 'Starbucks',
            amount: 5.75,
            date: Date.iso8601('2017-06-10')
          )]
        end
      end

      context 'when the expense lacks a payee' do
        # TODO: REFACTOR REPEATED CODE
        it 'rejects the expense as invalid if payee is not present' do
          expense.delete('payee')

          result = ledger.record(expense)
          expect(result).to_not be_success
          expect(result.expense_id).to eq(nil)
          expect(result.error_message).to include('`payee` is required')

          expect(DB[:expenses].count).to eq(0)
        end

        it 'rejects the expense as invalid if the amount is not present' do
          expense.delete('amount')

          result = ledger.record(expense)
          expect(result).to_not be_success
          expect(result.expense_id).to eq(nil)
          expect(result.error_message).to include('`amount` is required')
        end

        it 'rejects the expense as invalid if the date is not present' do
          expense.delete('date')

          result = ledger.record(expense)
          expect(result).to_not be_success
          expect(result.expense_id).to eq(nil)
          expect(result.error_message).to include('`date` is required')
        end
      end
    end

    describe '#expenses_on' do
      it 'return all the expenses for a provided date' do
        result1 = ledger.record(expense.merge('date' => '2017-06-10'))
        result2 = ledger.record(expense.merge('date' => '2017-06-10'))

        expect(ledger.expenses_on('2017-06-10')).to contain_exactly(
          a_hash_including(id: result1.expense_id),
          a_hash_including(id: result2.expense_id)
        )
      end

      it 'returns a blank array when there are no matching expenses' do
        expect(ledger.expenses_on('2017-06-13')).to eq([])
      end
    end
  end
end
