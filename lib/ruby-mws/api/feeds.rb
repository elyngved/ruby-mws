# Logic for submitting XML data "feeds" to Amazon and retrieving the response

module MWS
  module API

    module Feeds
      def submit_feed(feed_type, xml)
        puts "ruby-mws: Sending #{feed_type} feed to Amazon MWS. Body: #{xml.size > 1000 ? xml[0...1000] + '...' : xml}" if $VERBOSE
        response = send_request(:submit_feed, :feed_type => feed_type, :body => xml, :verb => :post, :content_md5 => true, :content_type => 'application/xml')

        # Amazon returns FeedSubmissionId, which we use to check if submission was successful
        submission_id = response.feed_submission_info.feed_submission_id
        puts "ruby-mws: Got submission ID #{submission_id}" if $VERBOSE

        # first wait until Amazon is finished processing the feed
        # this usually takes at least something close to a minute
        # so don't check back too frequently -- otherwise our FeedSubmissionList
        #   queries will be throttled
        while true
          sleep(30)
          puts "ruby-mws: Checking if feed processing is done..." if $VERBOSE
          response = send_request(:get_feed_submission_list, :lists => {:feed_submission_ids => "FeedSubmissionIdList.Id"}, :feed_submission_ids => [submission_id])
          puts "ruby-mws: Got feed status: #{response.feed_submission_info.feed_processing_status}" if $VERBOSE
          break if response.feed_submission_info.feed_processing_status == '_DONE_'
        end

        # then check whether there were any errors
        puts "ruby-mws: Checking feed processing result..." if $VERBOSE
        response = send_request(:get_feed_submission_result, :feed_submission_id => submission_id)
        if $VERBOSE
          summary = response.message.processing_report.processing_summary
          result  = response.message.processing_report.result
          puts "ruby-mws: #{summary.messages_successful} messages were successful, #{summary.messages_with_warning} had warnings, #{summary.messages_with_error} had errors.#{" Got result: #{result.inspect}" if result}"
        end

        errors = ""
        [*response.message.processing_report.result].each do |result|
          if %w{Warning Error}.include? result.result_code
            errors << result.result_description
            if result.additional_info && !result.additional_info.empty?
              errors << " (additional info: "
              errors << result.additional_info.map { |k,v| "#{k}=#{v}" }.join(' ')
              errors << ")"
            end
            errors << "\n"
          end
        end

        errors.empty? || (raise ErrorResponse, errors)
      end
    end

  end
end
