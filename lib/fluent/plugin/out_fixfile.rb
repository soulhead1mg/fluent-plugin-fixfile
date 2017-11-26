#
# Copyright 2017- soulhead
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"
require "fluent/plugin/out_file"

module Fluent
  module Plugin
    class FixfileOutput < Fluent::Plugin::FileOutput
      Fluent::Plugin.register_output("fixfile", self)

      def configure(conf)
        super
      end

      def start
        super
      end

      def shutdown
        super
      end

      def format(tag, time, record)
        super
      end

      def write(chunk)
        path_suffix = @add_path_suffix ? @path_suffix : ''
        comp_suffix = compression_suffix(@compress_method)
        index_placeholder = @append ? '' : '_**'
        path = "#{@path}#{index_placeholder}#{path_suffix}#{comp_suffix}"
        #path = extract_placeholders(@path_template, chunk.metadata)
        FileUtils.mkdir_p File.dirname(path), mode: @dir_perm

        writer = case
                 when @compress_method.nil?
                   method(:write_without_compression)
                 when @compress_method == :gzip
                   if @buffer.compress != :gzip || @recompress
                     method(:write_gzip_with_compression)
                   else
                     method(:write_gzip_from_gzipped_chunk)
                   end
                 else
                   raise "BUG: unknown compression method #{@compress_method}"
                 end

        if @append
          writer.call(path, chunk)
        else
          find_filepath_available(path, with_lock: @need_lock) do |actual_path|
            writer.call(actual_path, chunk)
            path = actual_path
          end
        end

        @last_written_path = path
      end

    end
  end
end
