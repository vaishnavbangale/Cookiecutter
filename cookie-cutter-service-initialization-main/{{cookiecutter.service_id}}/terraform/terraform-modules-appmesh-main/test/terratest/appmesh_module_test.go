package test

import (
	"testing"
	"os/exec"
	"fmt"
	"bytes"
	"io/ioutil"
	"math/rand"
	"time"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Helper functions
func Shellout(command string) (error, string, string) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command("bash", "-c", command)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	return err, stdout.String(), stderr.String()
}

func RandStringGen(n int) string {
	rand.Seed(time.Now().UTC().UnixNano())
    bytes := make([]byte, n)
    for i := 0; i < n; i++ {
        bytes[i] = byte((97 + rand.Intn(25)))
    }	
    return string(bytes)
}

// Test the Terraform module in examples/ using Terratest.
func TestEcsServiceModule(t *testing.T) {
	t.Parallel()
	random_id := RandStringGen(7)
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
		Upgrade:      true,
		Vars: map[string]interface{}{
			"id": random_id,
		  },		
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	appmesh_output := terraform.OutputMap(t, terraformOptions, "appmesh_output")
	assert.Contains(t, appmesh_output, "cloud_map_namespace")
	assert.Contains(t, appmesh_output, "cloud_map_id")
	assert.Contains(t, appmesh_output, "cloud_map_arn")
	assert.Contains(t, appmesh_output, "cloud_map_hosted_zone")
	assert.Contains(t, appmesh_output, "app_mesh_id")
	assert.Contains(t, appmesh_output, "app_mesh_arn")
	assert.Contains(t, appmesh_output, "cloud_map_acmpca_ca_arn")
	assert.Contains(t, appmesh_output, "cloud_map_acmpca_arn")
	assert.Contains(t, appmesh_output, "cloud_map_acm_arn")

	appmesh_service_output := terraform.OutputMap(t, terraformOptions, "appmesh_service_output")
	assert.Contains(t, appmesh_service_output, "cloud_map_service_id")
	assert.Contains(t, appmesh_service_output, "cloud_map_service_arn")
	assert.Contains(t, appmesh_service_output, "cloud_map_service_name")
	assert.Contains(t, appmesh_service_output, "virtual_service_id")
	assert.Contains(t, appmesh_service_output, "virtual_service_arn")
	assert.Contains(t, appmesh_service_output, "virtual_service_name")
	assert.Contains(t, appmesh_service_output, "virtual_router_id")
	assert.Contains(t, appmesh_service_output, "virtual_router_arn")
	assert.Contains(t, appmesh_service_output, "virtual_router_name")
	assert.Contains(t, appmesh_service_output, "virtual_nodes")
	assert.Contains(t, appmesh_service_output, "virtual_routes")
	assert.Contains(t, appmesh_service_output, "virtual_gateway_route")


	// publish output to temp inspec files dir
	output_json := terraform.Output(t, terraformOptions, "output_json")
	err := ioutil.WriteFile("../inspec/files/output.json", []byte(output_json), 0755)
	if err != nil {
		fmt.Println("Error writing outputs to file")
	}
	assert.Nil(t, err)

	// Run inspec tests 
	shellCmd := fmt.Sprintf("inspec exec ../inspec -t aws://us-east-1 --chef-license accept --reporter cli")
	err, out, errout := Shellout(shellCmd)
	fmt.Println("--- stdout ---")
	fmt.Println(out)
	fmt.Println("--- stderr ---")
	fmt.Println(errout)
	assert.Equal(t, errout, "")
	assert.Nil(t, err)	
}
