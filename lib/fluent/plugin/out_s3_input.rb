require 'csv'
require 'json'
require 'zip'

module Fluent
  class S3InputOutput < Output

    Fluent::Plugin.register_output('s3_input', self)

    # Define `router` method of v0.12 to support v0.10 or earlier
    unless method_defined?(:router)
      define_method("router") { Fluent::Engine }
    end

    config_param :aws_key_id, :string, :default => ENV['AWS_ACCESS_KEY_ID'], :secret => true
    config_param :aws_sec_key, :string, :default => ENV['AWS_SECRET_ACCESS_KEY'], :secret => true
    config_param :s3_bucket_key
    config_param :s3_object_key_key
    config_param :tag
    config_param :merge_record, :bool, :default => false
    config_param :record_key, :string, :default => nil
    config_param :remove_keys, :array, :default => []
    config_param :time_keys, :array, :default => []
    config_param :time_format, :string, :default => "%Y-%m-%dT%H:%M:%S"
    config_param :gzip_exts, :array, :default => []
    config_param :zip_exts, :array, :default => []
    config_param :format, :string, :default => 'json'

    attr_accessor :s3

    def initialize
      super
      require 'net/http'
      require 'oj'
      require 'aws-sdk'
    end

    def configure(conf)
      super

      if @aws_key_id and @aws_sec_key
        @s3 = Aws::S3::Client.new(
          region: "us-east-1",
          access_key_id: @aws_key_id,
          secret_access_key: @aws_sec_key,
        )
      else
        @s3 = Aws::S3::Client.new()
      end
    end
    
    # Allow JSON data in a couple of formats
    # {} single event
    # [{},{}] array of events
    # {}\n{}\n{} concatenated events (flume)
    def normalize_json(json)
      if json[0] != "["
        json=json.gsub /}\n{/,"},{" 
        json="[#{json}]"
      end
      json
    end

    def emit(tag, es, chain)
      begin
        tag_parts = tag.split('.')
        es.each { |time, record|
          s3_bucket = record[s3_bucket_key]
          s3_key = record[s3_object_key_key]
          s3_key_ext = s3_key.split(".")[-1]
          resp = s3.get_object(bucket: s3_bucket, key: s3_key) 

          if @gzip_exts.include?(s3_key_ext)
            input = Zlib::GzipReader.new(resp.body)
          elsif @zip_exts.include?(s3_key_ext)
            io = Zip::InputStream.new(resp.body)
            input = io.get_next_entry
            #input = Zip::File.open(resp.body).entries.first.get_input_stream
          else
            input = resp.body
          end

          new_record = {}
          if @merge_record
            new_record = {}.merge(record)
          end
   
          s3_record = {} 
          if @format == 'json'
            json_data=normalize_json input.read
            s3_record = Oj.load(json_data)
          elsif @format == 'csv'
            data = input.read
            File.open("/tmp/s3debug", 'w') { |file| file.write(data) } 
            s3_record=CSV.parse(data).to_json
          else
            raise "Unsupported format - #{@format}"
          end

          # parse the time from the record
          @time_keys.each do |time_key|
            puts "Look for #{time_key} in #{new_record}"
            if s3_record.include? time_key
              puts "Reset time for #{time_key}"
              time=Time.strptime(new_record[time_key], @time_format).to_i
              puts "Setting time to #{time}"
              break
            end
          end

          if @record_key == nil  
            tmp_record=s3_record.merge(new_record)
            new_record=tmp_record
          else
            new_record[record_key]=s3_record
          end
        
          @remove_keys.each do |key_to_remove|
            new_record.delete(key_to_remove)
          end

          router.emit(@tag, time, new_record)
        }
        chain.next
      rescue StandardError => e
        $log.warn "s3_input: #{e.class} #{e.message} #{e.backtrace.join(', ')}"
      end
    end
  end
end
