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
      require 'uri'

      def initialize(message, config)
        @message = message
        @config = config
      end

      def perform
        connect
        if @config[:request_type] == "post"
          post
        else
          get
        end
      end

      def connect
        @uri = URI.parse(@config[:server_uri] + @message[:status])
        @http = Net::HTTP.new(@uri.host, @uri.port)
      end

      def get
        path = "/hubot/#{@message[:status]}?user=#{@message[:user]}&project=#{@message[:project]}&branch=#{@message[:branch]}&tag=#{@message[:tag]}"
        headers = {'Accept' => 'plain/text',
                   'Content-Type' => 'plain/text'}
        response, data = @http.get(path, headers)

        { :message => @message, :response => response, :data => data }
      end

      def post
        request = Net::HTTP::Post.new(@uri.request_uri)
        request.set_form_data({ :status => @message[:status],
                                :user => @message[:user],
                                :project => @message[:project],
                                :branch => @message[:branch],
                                :tag => @message[:tag],
                                :build_stdout => @message[:build_stdout]
                              })
        response = @http.request(request)
      end
    end

    private
      def enqueue(message, config)
        Delayed::Job.enqueue(Job.new(message, config))
      end

      def build_info(build, status)
        first_failure_stdout = build.parts.last.output.select {|o| !o.ok? }.first.stdout
        { :status => status,
          :user =>"#{build.email}",
          :project => "#{build.project.name}",
          :branch =>"#{build.project.vcs_branch}",
          :tag => "#{build.commit}",
          :build_stdout => "#{first_failure_stdout.join}"
        }
      end
  end
end
