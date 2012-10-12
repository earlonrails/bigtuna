module BigTuna
  class Hooks::Hubot < Hooks::Base
    NAME = "hubot"

    def build_fixed(build, config)
      enqueue(build_info(build, "great-commit"), config)
    end

    def build_still_fails(build, config)
      enqueue(build_info(build, "broken-spec"), config)
    end

    def build_failed(build, config)
      enqueue(build_info(build, "broken-spec"), config)
    end

    class Job
      require 'net/http'
      require 'net/https'

      def initialize(message, config)
        @message = message
        @config = config
      end

      def perform
        path = "/hubot/#{@message[:status]}?user=#{@message[:user]}&project=#{@message[:project]}&branch=#{@message[:branch]}&tag=#{@message[:tag]}"
        headers = {'Accept' => 'plain/text',
                   'Content-Type' => 'plain/text'}

        http = Net::HTTP.new(@config[:server], 5555)
        # http.use_ssl = true
        response, data = http.get(path, headers)

        { :message => @message, :response => response, :data => data }
      end
    end

    private
      def enqueue(message, config)
        Delayed::Job.enqueue(Job.new(message, config))
      end

      def build_info(build, status)
        { :status => status,
          :user =>"#{build.email}",
          :project => "#{build.project.name}",
          :branch =>"#{build.project.vcs_branch}",
          :tag =>"#{build.commit}"
        }
      end
  end
end
