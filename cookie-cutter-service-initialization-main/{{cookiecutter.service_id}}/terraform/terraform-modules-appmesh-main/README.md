# terraform-modules-appmesh #

Terraform module repository to build appmesh and cloud map service discovery namespace
Map of appmesh routers/services configuration can be passed as variables to create the resources together with the mesh.

For resources within the mesh:
- See submodule in modules/service directory (README.md inside)
- App Mesh virtual gateway and virtual gateway routes are not deployed by this module

# usage #
```hcl
module "appmesh" {
  source = "git@github.com:HappyMoneyInc/terraform-modules-appmesh.git?ref=v2.0.8"

  tags = {
    "Terraform" = "True"
  }
  vpc_id                         = "vpc-03207458f7f9b482e"
  cloudmap_namespace             = "example.local"
  cloudmap_namespace_description = "Example cloudmap"
  mesh_name          = "example-sandbox"
  mesh_egress_filter = "ALLOW_ALL"
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| tags | Common tags for all resources. | map(string) | n/a | yes |
| vpc_id | VPC id for cloud map network configuration | string | n/a | yes |
| cloudmap_namespace | Value of the cloudmap service discovery namespace | string | n/a | yes |
| cloudmap_namespace_description | Description of the cloudmap service discovery namespace | string | `null` | no |
| cloudmap_tls_cert_enabled | Flag to enable creating ACM managed ACM-PCA for the cloudmap namespace | bool | `false` | no |
| mesh_name | The name to use for the service mesh | string | n/a | yes |
| mesh_egress_filter | App mesh egress filter type. Valid values: `ALLOW_ALL`, `DROP_ALL`  | string | `DROP_ALL` | no |
| region_abbrv | Region abbreviation | string | `ue1` | no |
| use_assume_role | Use assume provider role before running aws cli to set acmpca permission if using provider with assume_role since local-exec does not inherit provider. | bool | `false` | no |
| acmpca_validity_type | Determines how `acmpca_validity_value` is interpreted. Valid values: `DAYS`, `MONTHS`, `YEARS`, `ABSOLUTE`, `END_DATE` | string | `YEARS` | no |
| acmpca_validity_value | If type is `DAYS`, `MONTHS`, or `YEARS`, the relative time until the certificate expires. If type is `ABSOLUTE`, the date in seconds since the Unix epoch. If type is `END_DATE`, the date in RFC 3339 format. | number | `20` | no |

## Outputs
| Name | Description |
|------|-------------|
| cloud_map_namespace | The Name of the cloud map namespace |
| cloud_map_id | The ID of the cloud map namespace |
| cloud_map_arn | The ID of the cloud map arn |
| cloud_map_hosted_zone | The ID of the hosted zone in aws route 53 created for the namespace. |
| app_mesh_id | The ID of the service mesh |
| app_mesh_arn | The ARN of the service mesh |
| cloud_map_acmpca_ca_arn | Certificate authority arn of cloudmap root acmpca |
| cloud_map_acmpca_arn | Certificate authority arn of cloudmap root acmpca certificate |
| cloud_map_acm_arn | ACM arn of cloudmap domain certificate |
