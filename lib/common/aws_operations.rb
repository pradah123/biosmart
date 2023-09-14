require 'aws-sdk'

module AWSOperations
  def self.get_s3_client
    begin
      # TBD: Read region and credentials values from encrypted aws config file and
      # replace them with 'xyz' values below
      client = Aws::S3::Client.new(
        region: 'xyz',
        credentials: Aws::Credentials.new('xyz', 'xyz')
      )
      return client
    rescue => e
      return 0
      Rails.logger.error("Unable to get s3 client => #{e}")
    end
  end

  def self.aws_s3_file_upload(s3_client, file_path, key)
    file_name = file_path.match(/.*\/(.*)$/)[1]
    key += file_name
    begin
      File.open(file_path, 'rb') do |file|
        # TBD: Read bucket value from encrypted aws config file and
        # replace them with 'xyz' value below
        s3_client.put_object(bucket: 'xyz', key: key, body: file)
      end
    rescue => e
      Rails.logger.error("Unable to upload file #{file_path} to key #{key} => #{e}")
    end
  end
end
