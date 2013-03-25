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
        ftp_host      = @config[:ftp_host]
        user_name     = @config[:username]
        identity_file = @config[:identity_file]
        ftp_location.sub!(/\./, Time.now.strftime("_%m_%d_%Y_%H%M.")) if (@config[:add_timestamp].to_i == 1)
        Net::SCP.upload!(ftp_host, user_name, file, ftp_location, :key => identity_file)
      end
    end
  end
end
