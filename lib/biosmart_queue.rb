class BiosmartQueue
    def initialize
        @sqs_client = Aws::SQS::Client.new(
            region: ENV["SQS_REGION"] || "ap-southeast-2"
        )
    end

    def enqueue(message)
        queue_url = ENV["SQS_URL"] ||
                     "https://sqs.ap-southeast-2.amazonaws.com/461130176523/biosmart-import-queue-test"
        @sqs_client.send_message(
            queue_url: queue_url,
            message_body: message
        )
    end
end
