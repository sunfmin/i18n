# encoding: utf-8
$KCODE = 'u' if RUBY_VERSION <= '1.9'

require 'rubygems'
require 'test/unit'

require 'test_setup/options'
require 'test_setup/bundle'
require 'test_setup/active_record'
require 'test_setup/rufus_tokyo'
require 'mocha'

class Test::Unit::TestCase
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end

  def self.with_mocha
    yield if Object.respond_to?(:expects)
  end

  def teardown
    I18n.locale = nil
    I18n.default_locale = :en
    I18n.load_path = []
    I18n.available_locales = nil
    I18n.backend = nil
  end

  def translations
    I18n.backend.instance_variable_get(:@translations)
  end

  def store_translations(*args)
    data   = args.pop
    locale = args.pop || :en
    I18n.backend.store_translations(locale, data)
  end

  def locales_dir
    File.dirname(__FILE__) + '/test_data/locales'
  end

  def euc_jp(string)
    string.encode!(Encoding::EUC_JP)
  end

  def can_store_procs?
    active_record_available? && non_active_record_backend?
  end

  def active_record_available?
    defined?(ActiveRecord)
  end

  def non_active_record_backend?
    I18n.backend.class != I18n::Backend::ActiveRecord or
    I18n::Backend::ActiveRecord.included_modules.include?(I18n::Backend::ActiveRecord::StoreProcs)
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end

Object.class_eval do
  def meta_class
    class << self; self; end
  end
end unless Object.method_defined?(:meta_class)
