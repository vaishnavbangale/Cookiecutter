# Read from output file
file_name = "output.json"
json_file = inspec.profile.file(file_name)
attributes = JSON.parse(json_file)

cloud_map_namespace = attributes['cloud_map_namespace']
cloud_map_id = attributes['cloud_map_id']
cloud_map_arn = attributes['cloud_map_arn']
cloud_map_hosted_zone = attributes['cloud_map_hosted_zone']
cloud_map_service = attributes['cloud_map_service']
cloudmap_namespace_description = attributes['cloudmap_namespace_description']
app_mesh_name = attributes['app_mesh_name']
app_mesh_id = attributes['app_mesh_id']
app_mesh_arn = attributes['app_mesh_arn']
app_mesh_router = attributes['app_mesh_router']
app_mesh_virtual_service = attributes['app_mesh_virtual_service']
virtual_node_test = attributes['virtual_node_test']

#--------------------------------------
control 'service_discovery' do
    impact 1.0
    title 'Test cloud map resources'

    describe aws_service_discovery_namespace(id: cloud_map_id) do
        it { should exist }
        its('arn') { should cmp cloud_map_arn }
        its('name') { should cmp cloud_map_namespace }
        its('description') { should cmp cloudmap_namespace_description }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_service_discovery_service(id: cloud_map_service["id"]) do
        it { should exist }
        its('arn') { should cmp cloud_map_service["arn"] }
        its('name') { should cmp cloud_map_service["name"] }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end
end

control 'app_mesh' do
    impact 1.0
    title 'Test app mesh resources'

    describe aws_appmesh_mesh(mesh_name: app_mesh_name) do
        it { should exist }
        its('metadata.arn') { should cmp app_mesh_arn }
        its('spec.egress_filter.type') { should cmp "ALLOW_ALL" }
        its('status.status') { should cmp "ACTIVE" }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_appmesh_virtual_router(mesh_name: app_mesh_name, virtual_router_name: app_mesh_router["name"]) do
        it { should exist }
        its('mesh_name') { should cmp app_mesh_name }
        its('metadata.arn') { should cmp app_mesh_router["arn"] }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end

    describe aws_appmesh_virtual_service(mesh_name: app_mesh_name, virtual_service_name: app_mesh_virtual_service["name"]) do
        it { should exist }
        its('mesh_name') { should cmp app_mesh_name }
        its('metadata.arn') { should cmp app_mesh_virtual_service["arn"] }
        its('status.status') { should cmp "ACTIVE" }
        its('spec.provider.virtual_router.virtual_router_name') { should cmp app_mesh_router["name"] }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end  
end

control 'app_mesh_node' do
    impact 1.0
    title 'Test app mesh node resources'

    describe aws_appmesh_virtual_node(mesh_name: app_mesh_name, virtual_node_name: virtual_node_test["node_name"]) do
        it { should exist }
        its('mesh_name') { should cmp app_mesh_name }
        its('metadata.arn') { should cmp virtual_node_test["node_arn"] }
        its('spec.service_discovery.aws_cloud_map.namespace_name') { should cmp cloud_map_namespace }
        its('tags') { should include(key: "account", value: "sandbox") }
        its('tags') { should include(key: "terraform", value: "true") }
        its('tags') { should include(key: "env", value: "sandbox") }
        its('tags') { should include(key: "terraform-repo", value: "terraform-modules-appmesh") }
        its('tags') { should include(key: "hm-service", value: "test") }
        its('tags') { should include(key: "hm-project", value: "devops") }
        its('tags') { should include(key: "public-facing", value: "false") }
        its('tags') { should include(key: "region", value: "us-east-1") }
    end
end