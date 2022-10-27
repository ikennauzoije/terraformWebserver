#--------------------------------------------------
# Build Webserver during Bootstrap
#--------------------------------------------------

provider "aws" {
  region     = var.aws_region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# Provide the data sources
# Set the local variables
# Create the Elastic IP
# Create the EC2 Web Server
# Create the Application and Database servers
# Create the Security Group

# --------------- DATA SOURCES for Output and Use in Code ------------ #
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "currentAZ" {}
data "aws_vpcs" "vpcs" {} // This gets data on all VPCs in the account

data "aws_ami" "latest_linux" {
  owners      = ["137112412989"] // Owner Account ID gotten from the Amazon AMI page for the linux image
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"] // Dates and version numbers are replaced with a * to always get the latest
  }
}

# Use local variables 
locals {
  Region_fullname   = data.aws_region.current.description
  Number_of_AZs     = length(data.aws_availability_zones.currentAZ.names)
  Names_of_AZs      = join(",", data.aws_availability_zones.currentAZ.names)
  Full_Project_Name = "${var.tags["Project"]} running in ${local.Region_fullname}"
}

locals {
  Region_Info = "This Resource is in ${local.Region_fullname} consisting of ${local.Number_of_AZs} AZs"
}


# Create Elastic IP for the Web instance
resource "aws_eip" "instance_eip" {
  instance = aws_instance.web_server.id
  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} EIP for WebServer"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
  // ${var.tags["Environment"]} Extracts the environment attribute of the tag variable and use it in the name attribute of the tag
}


# Create EC2 instances for web server
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.latest_linux.id // Amazon Linux2 ami from the data source above
  instance_type          = lookup(var.instance_size, var.env, var.instance_size["my_default"])
  vpc_security_group_ids = [aws_security_group.General_SG.id]
  key_name               = var.key_pair

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 10
    encrypted   = (var.env == "prod") ? true : false // If the environment is prod, encrypt the root block device
  }

  dynamic "ebs_block_device" {
    for_each = var.env == "prod" ? [true] : [] // dynamic blocks take a list so if it isn't prod, give an empty list
    content {
      device_name = "/dev/sdb"
      volume_size = 40
      encrypted   = true
    }
  }

  user_data = templatefile("user_data.sh", {
    f_name = "Ikenna"
    l_name = "Uzoije"
    names  = ["Jeff", "Mike", "Beth"]
  }) // This passes these variables into the user_data.sh file and use those variables to build the user_data file

  // running a remote-exec command executes commands in the resource that's created (like a user_data)
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/ec2-user/terraform",
      "cd /home/ec2-user/terraform",
      "touch hello.txt",
      "echo 'Terraform was here ...' > terraform.txt"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip // Same as: aws_instance.web_server.public_ip
      private_key = file("${var.key_pair}.pem")
    }
  }

  depends_on = [ # This is an explicit dependency to force the dependency. You can add a list of resources the current one depends on
    aws_instance.servers["Application"],
    aws_instance.servers["Database"]
  ]

  volume_tags = { Name = "Disk-${var.env}" }

  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} WebServer Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  }) // This merges the unique name tag with the ones that are constant and expressed in the variables file

}


# Use a for_each loop and pass in a map of values to create new EC2 Instances for application and database servers
resource "aws_instance" "servers" {
  for_each      = var.servers_settings
  ami           = each.value["ami"]
  instance_type = each.value["instance_size"]

  root_block_device {
    volume_size = each.value["root_disksize"]
    encrypted   = each.value["encrypted"]
  }

  volume_tags = {
    Name = "Disk-${each.key}"
  }

  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} ${each.key} Server Built by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}


# ------- Instance Security Group Section ------------- #
# Create Security Group for instances
resource "aws_security_group" "General_SG" {
  name        = "General-SG"
  description = "Security Group for Web, App and DB Servers"

  dynamic "ingress" {
    # reduces the need to have multiple ingress blocks for each port. "Ingress" shows what kind of block it is replacing.
    for_each = lookup(var.port_list, var.env, var.port_list["prod"]) # The prod port_list is the default option
    content {
      description = "Allow all tcp traffic on production ports"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Putting one specific IP means only that IP address can access this Security Group
    }
  }

  egress {
    description      = "Allow all ports"
    from_port        = 0 # Means all ports allowed
    to_port          = 0
    protocol         = "-1" # Any protocol allowed
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name         = "${var.tags["Environment"]} General SG by Terraform"
    Project_Name = local.Full_Project_Name
    Region_Info  = local.Region_Info
  })
}
# --------- End of Instance Security Group Section --------- #
