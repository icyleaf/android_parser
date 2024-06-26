
module Android
  class NullLogger
    # @param _args Anything that we want to ignore
    # @return [nil]
    def unknown(*_args)
      nil
    end

    # @param _args Anything that we want to ignore
    # @return [nil]
    def fatal(*_args)
      nil
    end

    # @return [FALSE]
    def fatal?
      false
    end

    # @param _args Anything that we want to ignore
    # @return [nil]
    def error(*_args)
      nil
    end

    # @return [FALSE]
    def error?
      false
    end

    # @param _args Anything that we want to ignore
    # @return [nil]
    def warn(*_args)
      nil
    end

    # @return [FALSE]
    def warn?
      false
    end

    # @param _args Anything that we want to ignore
    # @return [nil]
    def info(*_args)
      nil
    end

    # @return [FALSE]
    def info?
      false
    end

    # @param _args Anything that we want to ignore
    # @return [nil]
    def debug(*_args)
      nil
    end

    # @return [FALSE]
    def debug?
      false
    end
  end
end
