require "helper"
require "fluent/plugin/out_fixfile.rb"

class FixfileOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::FixfileOutput).configure(conf)
  end
end
