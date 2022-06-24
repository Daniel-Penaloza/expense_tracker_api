# frozen_string_literal: true

require 'sequel'
DB = Sequel.sqlite("./db/#{ENV.fetch('RACK_ENV', 'development')}.db")
