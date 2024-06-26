# frozen_string_literal: true

require_relative 'android/null_logger'
require_relative 'android/configuration'
require_relative 'android/apk'
require_relative 'android/manifest'
require_relative 'android/axml_parser'
require_relative 'android/axml_writer'
require_relative 'android/dex'
require_relative 'android/resource'
require_relative 'android/utils'
require_relative 'android/layout'

module Android
  extend Configuration
end
