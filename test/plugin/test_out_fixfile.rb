require "helper"
require "fluent/plugin/out_fixfile.rb"
require "fileutils"
require "time"
require "timecop"
require "zlib"

class FixfileOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
  end

  TMP_DIR = File.expand_path(File.dirname(__FILE__) + "/../tmp/out_fixfile#{ENV['TEST_ENV_NUMBER']}")

  CONFIG = %{
    path #{TMP_DIR}/out_fixfile_test
    compress gz
    utc
    <buffer>
      timekey_use_utc true
    </buffer>
  }

  def check_gzipped_result(path, expect)
    result = ''
    File.open(path, "rb") { |io|
      loop do
        gzr = Zlib::GzipReader.new(io)
        result << gzr.read
        unused = gzr.unused
        gzr.finish
        break if unused.nil?
        io.pos -= unused.length
      end
    }
    assert_equal expect, result
  end

  sub_test_case 'write' do
    test 'basic case' do
      d = create_driver

      # out_file.rb:276
      #  index placeholder must have '_**'
      #assert_false File.exist?("#{TMP_DIR}/out_fixfile_test.0.log.gz")
      assert_false File.exist?("#{TMP_DIR}/out_fixfile_test_0.log.gz")

      time = event_time("2011-01-02 13:14:15 UTC")
      d.run(default_tag: 'test') do
        d.feed(time, {"a"=>1})
        d.feed(time, {"a"=>2})
      end

      #assert File.exist?("#{TMP_DIR}/out_fixfile_test.0.log.gz")
      #check_gzipped_result("#{TMP_DIR}/out_fixfile_test.0.log.gz", %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n] + %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n])
      assert File.exist?("#{TMP_DIR}/out_fixfile_test_0.log.gz")
      check_gzipped_result("#{TMP_DIR}/out_fixfile_test_0.log.gz", %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n] + %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n])
    end
  end

  sub_test_case 'format specified' do
    test 'append' do
      time = event_time("2011-01-02 13:14:15 UTC")
      formatted_lines = %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n] + %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n]

      write_once = ->(){
        d = create_driver %[
          path #{TMP_DIR}/out_fixfile_test
          compress gz
          utc
          append true
          <buffer>
            timekey_use_utc true
          </buffer>
        ]
        d.run(default_tag: 'test'){
          d.feed(time, {"a"=>1})
          d.feed(time, {"a"=>2})
        }
        d.instance.last_written_path
      }

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test.log.gz", path
      check_gzipped_result(path, formatted_lines)

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test.log.gz", path
      check_gzipped_result(path, formatted_lines * 2)

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test.log.gz", path
      check_gzipped_result(path, formatted_lines * 3)
    end

    test 'append disabled' do
      time = event_time("2011-01-02 13:14:15 UTC")
      formatted_lines = %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n] + %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n]

      write_once = ->(){
        d = create_driver %[
          path #{TMP_DIR}/out_fixfile_test
          compress gz
          utc
          <buffer>
            timekey_use_utc true
          </buffer>
        ]
        d.run(default_tag: 'test'){
          d.feed(time, {"a"=>1})
          d.feed(time, {"a"=>2})
        }
        d.instance.last_written_path
      }

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test_0.log.gz", path
      check_gzipped_result(path, formatted_lines)

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test_1.log.gz", path
      check_gzipped_result(path, formatted_lines)

      path = write_once.call
      assert_equal "#{TMP_DIR}/out_fixfile_test_2.log.gz", path
      check_gzipped_result(path, formatted_lines)
    end
  end

  private

  def create_driver(conf = CONFIG, opts = {})
    Fluent::Test::Driver::Output.new(Fluent::Plugin::FixfileOutput).configure(conf)
  end
end
