file_name = "output.json"
json_file = inspec.profile.file(file_name)
attributes = JSON.parse(json_file)

monitor_id = attributes['monitor_id']
dashboard_id = attributes['dashboard_id']

control 'datadog' do
    impact 1.0
    title 'Test datadog dashboard and monitor'

    describe datadog_monitor(monitor_id) do
        it { should exist }
    end

    describe datadog_dashboard(dashboard_id) do
        it { should exist }
    end
end