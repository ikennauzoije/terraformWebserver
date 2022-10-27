# ---------------------- OUTPUT SECTION ------------------------------ #
# Moving this section to the outputs.tf file

// AWS Region Name, Description, Account ID, AZs
output "region_name" {
  value = data.aws_region.current.name
}

output "region_description" {
  value = data.aws_region.current.description
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  value = data.aws_availability_zones.currentAZ.names
}

// VPC Outputs
output "all_vpc_ids" {
  value = data.aws_vpcs.vpcs.ids
}

// Security Group IDs
output "my_security_group_id" {
  value = aws_security_group.General_SG.id
}

// Print out instance ID with public and private IP
output "instance_info" {
  value = [
    // Prints out info on the web_server
    "Server with ID: ${aws_instance.web_server.id} has Public IP: ${aws_instance.web_server.public_ip} and Private IP: ${aws_instance.web_server.private_ip}",
    // Prints out info on the application and database server
    [
      for x in aws_instance.servers :
      "Server with ID: ${x.id} has Public IP: ${x.public_ip} and Private IP: ${x.private_ip}"
    ]
  ]
}

# -------- End of Output Section --------------------------------------------- #
