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
	<match sqs.s3.event>
	  type s3_input
	  s3_bucket_key s3_bucket
	  s3_object_key_key s3_object
          uncompress gzip
          tag s3.file.contents
	</filter>

	# Emit each record in the cloudtrail json document as a new event
	<match s3.file.contents>
	  type record_splitter
	  split_key Records
	  tag cloudtrail
	</match>
