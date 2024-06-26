module Android
  module Configuration
    attr_writer :logger

    def configure
      yield self
    end

    def logger
      @logger ||= NullLogger.new
    end
  end
end
