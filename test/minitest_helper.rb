Gem.suffix_pattern

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/hooks/default'
require 'minitest/global_expectations/autorun'
