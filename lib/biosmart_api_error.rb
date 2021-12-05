class BiosmartAPIError < StandardError
    EXCEPTION_TYPE = "biosmart-api-error"

    def initialize(msg="Unknown error occurred", exception_type=EXCEPTION_TYPE)
        @exception_type = exception_type
        super(msg)
    end
end
