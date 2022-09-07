require 'datadog_api_client'

class DDConnection
    def initialize()
        DatadogAPIClient::V1.configure do |config|
            config.api_key = ENV['DD_API_KEY']
            config.application_key = ENV['DD_APP_KEY']
        end
    end
    
    def monitor_api_client
        return DatadogAPIClient::V1::MonitorsAPI.new
    end

    def dashboard_api_client
        return DatadogAPIClient::V1::DashboardsAPI.new
    end     
end

class DatadogMonitorResource < Inspec.resource(1)
    name 'datadog_monitor'
    desc 'Verifies settings for a Datadog Monitor'
  
    example "
      describe datadog_monitor(monitor_id) do
        it { should exist }
      end
    "
    attr_reader :monitor_id, :result

    def initialize(opts = {})
        opts = { monitor_id: opts } if opts.is_a?(String)
        @monitor_id = opts[:monitor_id]
        dd_client = DDConnection.new()
        begin
            # Get a monitor's details
            @result = dd_client.monitor_api_client.get_monitor(@monitor_id)
        rescue DatadogAPIClient::V1::APIError => e
            @result = nil
        end
    end

    def exists?
        !@result.nil?
    end
    
    def to_s
        "Datadog Monitor #{@monitor_id}"
    end
end

class DatadogDashboardResource < Inspec.resource(1)
    name 'datadog_dashboard'
    desc 'Verifies settings for a Datadog Dashboard'
  
    example "
      describe datadog_dashboard(dashboard_id) do
        it { should exist }
      end
    "
    attr_reader :opts, :dashboard_id, :result

    def initialize(opts = {})
        opts = { dashboard_id: opts } if opts.is_a?(String)
        @dashboard_id = opts[:dashboard_id]
        dd_client = DDConnection.new()
        begin
            # Get a dashboard's details
            @result = dd_client.dashboard_api_client.get_dashboard(@dashboard_id)
        rescue DatadogAPIClient::V1::APIError => e
            @result = nil
        end
    end

    def exists?
        !@result.nil?
    end
    
    def to_s
        "Datadog Dashboard #{@dashboard_id}"
    end
end