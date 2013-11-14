module MWS
  module API

    class Reports < Base

      def product_skus_and_quantities
        report = get_report('_GET_MERCHANT_LISTINGS_DATA_LITER_')
        report = report.lines.map { |l| sku,quantity = l.chomp.split("\t"); [sku, quantity.to_i] }

        if report[0][0] != 'seller-sku'
          raise "Unexpected format for _GET_MERCHANT_LISTINGS_DATA_LITER_ report. Report contents: #{report.inspect}"
        end

        report.shift
        Hash[report]
      end

      private
      def get_report(type)
        puts "ruby-mws: Requesting #{type} report from Amazon" if $VERBOSE
        response = send_request(:request_report, :report_type => type)

        # Amazon returns ReportRequestId, which we can use to retrieve the results
        request_id = response.report_request_info.report_request_id
        puts "ruby-mws: Got report request ID #{request_id}" if $VERBOSE

        # first wait until Amazon has generated the report
        # this usually takes at least something close to a minute
        # so don't check back too frequently -- otherwise our FeedSubmissionList
        #   queries will be throttled
        while true
          sleep(30)
          puts "ruby-mws: Checking if report processing is done..." if $VERBOSE
          response = send_request(:get_report_request_list, :report_request_ids => [request_id],
            :lists => {:report_request_ids => 'ReportRequestIdList.Id'})

          status = response.report_request_info.report_processing_status
          puts "ruby-mws: Got feed status: #{status}" if $VERBOSE
          break if status == '_DONE_'
        end

        # now get the actual report results
        report_id = response.report_request_info.generated_report_id

        if report_id.nil? || report_id.empty?
          puts "ruby-mws: GeneratedReportId was not returned, retrieving it using GetReportList request" if $VERBOSE
          response = send_request(:get_report_list, :report_request_ids => [request_id],
            :lists => {:report_request_ids => 'ReportRequestIdList.Id'})
          report_id = response.report_info.report_id
        end

        puts "ruby-mws: Retrieving report result (report ID = #{report_id})..." if $VERBOSE
        response = send_request(:get_report, :report_id => report_id, :format => :plain)

        #errors = ""
        #[*response.message.processing_report.result].each do |result|
        #  if %w{Warning Error}.include? result.result_code
        #    errors << result.result_description
        #    if result.additional_info && !result.additional_info.empty?
        #      errors << " (additional info: "
        #      errors << result.additional_info.map { |k,v| "#{k}=#{v}" }.join(' ')
        #      errors << ")"
        #    end
        #    errors << "\n"
        #  end
        #end

        #errors.empty? || (raise ErrorResponse, errors)

        response
      end
    end
  end
end