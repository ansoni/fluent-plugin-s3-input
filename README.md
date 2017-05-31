# fluent-plugin-s3-input
Fluentd plugin that will read a json file from S3.  This plugin can be used to
handle S3 Event Notifications such as cloudtrail API logs

# Usage

S3 Event Example Intake 

	# Get Notified of JSON document in S3
	<source>
	  type sqs
	  tag sqs.s3.event
	  sqs_url SQS_S3_NOTFICATION_QUEUE
	  receive_interval 1
	  max_number_of_messages 10
	  wait_time_seconds 20
	</source>

	# Remove SQS encapsulation
	<filter sqs.s3.events>
	  type parser
	  format json
	  key_name body
	</filter>

	# Transform to Array
	<match sqs.s3.events>
	  type record_splitter
	  split_key Records
	  tag sqs.s3.event
	</match>

	# extract s3_path
	<filter sqs.s3.event>
	  @type record_transformer
	  enable_ruby
	  renew_record true
	  <record>
            s3_bucket ${record['s3']['object']['key']}
	    s3_key ${record['s3']['bucket']['name']}
	  </record>
	</filter>
	
	# read and emit the json object
	# this plugin!
        # if the document is an object, it will be emitted.
        # if the document is an array, then each element of the array will be emitted
	<match sqs.s3.event>
	  type s3_input
	  merge_record no
	  s3_bucket_key s3_bucket
	  s3_object_key_key s3_object
	  uncompress gzip
	  tag s3.file.contents
	</filter>

# params
    tag my.new.tag : tag name to emit new record as
    uncompress gzip : decompression algorithm (only gzip:-/)
    s3_bucket_key my_s3_bucket : The name of your S3 bucket
    s3_object_key_key /some/cool/object : The path to your S3 object
    merge_record  yes|no : Do we merge or replace the input record
    remove_keys key1, key2 : keys that we remove after reading the s3 object
    compression_exts gz, zip : extensions that we uncompress.  Allows you to ingest both compressed and uncompressed files
    record_key : if set, the record will be placed in this key 
    aws_region : region to use.  Default to us-east-1

