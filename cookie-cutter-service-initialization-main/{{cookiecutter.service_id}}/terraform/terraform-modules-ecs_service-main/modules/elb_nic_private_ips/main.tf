variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "load_balancer_arn_suffix" {
  type = string
}

data "aws_network_interface" "network_load_balancer" {
  # Extract the ENIs associated with the network load balancer
  count = length(var.subnet_ids)

  filter {
    name   = "description"
    values = ["ELB ${var.load_balancer_arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [element(var.subnet_ids, count.index)]
  }
}

output "private_ip_cidrs" {
  value = formatlist(
    "%s/32",
    flatten(data.aws_network_interface.network_load_balancer.*.private_ips),
  )
}