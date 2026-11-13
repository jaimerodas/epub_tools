# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  skip '/test/'
end

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
