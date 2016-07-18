
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
    # supports: gzip
    config_param :uncompress, :string

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
        @s3 = Aws::S3::Client.new(region: "us-east-1")
      end
    end

    def emit(tag, es, chain)
      tag_parts = tag.split('.')
      es.each { |time, record|
        s3_bucket = record[s3_bucket_key]
        s3_key = record[s3_object_key_key]
        resp = s3.get_object(bucket: s3_bucket, key: s3_key) 
        if @uncompress && @uncompress == "gzip"
          input = Zlib::GzipReader.new(resp.body)
        else
          input = resp.body
        end
        new_record = Oj.load(input.read)
        router.emit(@tag, time, new_record)
      }
      chain.next
    rescue => e
      $log.warn "s3_input: #{e.class} #{e.message} #{e.backtrace.join(', ')}"
    end
  end
end
