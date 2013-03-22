module BigTuna
  class Hooks::Ftp < Hooks::Base
    NAME = "ftp"

    def build_passed(build, config)
      Delayed::Job.enqueue(Job.new(config))
    end

    def build_still_passes(build, config)
      Delayed::Job.enqueue(Job.new(config))
    end

    def build_fixed(build, config)
      Delayed::Job.enqueue(Job.new(config))
    end

    def build_still_fails(build, config)
      Delayed::Job.enqueue(Job.new(config))
    end

    def build_failed(build, config)
      Delayed::Job.enqueue(Job.new(config))
    end

    class Job
      def initialize(config)
        @config = config
      end

      def perform
        ftp_location  = @config[:ftp_location]
        file          = @config[:file_location]
        ftp_host      = @hook.configuration[:ftp_host]
        user_name     = @hook.configuration[:username]
        identity_file = @hook.configuration[:identity_file]
        Net::SCP.upload!(ftp_host, user_name, file, ftp_location, :key => identity_file)
      end
    end
  end
end
