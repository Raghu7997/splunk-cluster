provider "aws" {
  region = "${var.region}"
}

#################### VPC ########################
resource "aws_vpc" "main" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.name}-vpc"
    Location = "Ahmedabad"
  }
}

################### Internet gateway #############
resource "aws_internet_gateway" "splunk-internetgateway" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.name}-internet-gateway"
  }
}

################## Route Table #################
resource "aws_route_table" "splunk-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.splunk-internetgateway.id}"
  }
  tags {
    Name = "${var.name}-splunk-route-table"
  }
}

resource "aws_route_table_association" "application-a-association" {
  subnet_id      = "${aws_subnet.application-a.id}"
  route_table_id = "${aws_route_table.splunk-route-table.id}"
}
resource "aws_route_table_association" "application-a-association" {
  subnet_id      = "${aws_subnet.application-b.id}"
  route_table_id = "${aws_route_table.splunk-route-table.id}"
}
#################### subnets ####################
resource "aws_subnet" "application-a" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 0)}"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.name}-application-a"
  }
}
resource "aws_subnet" "application-b" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 1)}"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.name}-application-b"
  }
}

# resource "aws_subnet" "internal-a" {
#   vpc_id     = "${aws_vpc.main.id}"
#   cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 2)}"
#   availability_zone = "ap-south-1a"

#   tags = {
#     Name = "internal-a"
#   }
# }

# resource "aws_subnet" "internal-b" {
#   vpc_id     = "${aws_vpc.main.id}"
#   cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 3)}"
#   availability_zone = "ap-south-1b"

#   tags = {
#     Name = "internal-b"
#   }
# }

# resource "aws_subnet" "internet-a" {
#   vpc_id     = "${aws_vpc.main.id}"
#   cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 4)}"
#   availability_zone = "ap-south-1a"

#   tags = {
#     Name = "internet-a"
#   }
# }

# resource "aws_subnet" "internet-b" {
#   vpc_id     = "${aws_vpc.main.id}"
#   cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, 5)}"
#   availability_zone = "ap-south-1b"

#   tags = {
#     Name = "internet-b"
#   }
# }

###################### Security Groups ######################

resource "aws_security_group" "indexer-elb" {
  name        = "${var.name}-indexer-elb"
  vpc_id      = "${aws_vpc.main.id}"
  tags = {
    Name = "${var.name}-indexer-elb"
  }

  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "searchhead-elb" {
#   name        = "searchhead-elb"
#   vpc_id      = "${aws_vpc.main.id}"
#   tags = {
#     Name = "searchhead-elb"
#   }

#   ingress {
#     from_port   = 8000
#     to_port     = 8000
#     protocol    = "http"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 8089
#     to_port     = 8089
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 8191
#     to_port     = 8191
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 8090
#     to_port     = 8090
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 9997
#     to_port     = 9997
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress{
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

resource "aws_security_group" "splunk-node" {
  name        = "${var.name}-splunk-node"
  vpc_id      = "${aws_vpc.main.id}"
  tags = {
    Name = "${var.name}-splunk-node"
  }
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



###################### Load Balancers #######################

resource "aws_elb" "splunk-indexer-elb" {
  name               = "${var.name}-splunk-indexer-elb"
  availability_zones = ["${var.availability_zones}"]
  internal = "true"
  subnets = ["${aws_subnet.application-a.id}","${aws_subnet.application-b.id}"]
  security_groups = ["${aws_security_group.indexer-elb.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "${var.name}-splunk-indexer-elb"
    Type = "classic"
  }

  listener {
    instance_port     = 9997
    instance_protocol = "tcp"
    lb_port           = 9997
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    target              = "TCP:9997/"
    interval            = 5
  }

  
}

# resource "aws_elb" "searchhead" {
#   name               = "splunk-searchhead-elb"
#   availability_zones = ["${var.availability_zones}"]
#   internal = "true"
#   subnets = ["${aws_subnet.application-a.id}","${aws_subnet.application-b.id}"]
#   security_groups = ["${aws_security_group.searchhead-elb.id}"]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 60
#   connection_draining         = true
#   connection_draining_timeout = 300

#   tags = {
#     Name = "splunk-searchhead-elb"
#     Type = "classic"
#   }

#   listener {
#     instance_port     = 8000
#     instance_protocol = "https"
#     lb_port           = 8000
#     lb_protocol       = "https"
#     ssl_certificate_id = ""
#   }
#   listener {
#     instance_port     = 8089
#     instance_protocol = "https"
#     lb_port           = 8089
#     lb_protocol       = "https"
#     ssl_certificate_id = ""
#   }
#   listener {
#     instance_port     = 443
#     instance_protocol = "https"
#     lb_port           = 8000
#     lb_protocol       = "https"
#     ssl_certificate_id = ""
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#     timeout             = 4
#     target              = "TCP:9997/"
#     interval            = 5
#   }
# }


####################### ELB Attechment ####################
resource "aws_elb_attachment" "splunk-node" {
  elb      = "${aws_elb.splunk-indexer-elb.id}"
  instance = "${aws_instance.indexer.id}"
}
# ######################## Template Part ###################

# resource "template_file" "web_conf" {
#     template    = "${file("${path.module}/web_conf.tpl")}"
#     vars     {
#         httpport        = "${var.httpport}"
#         mgmtHostPort    = "${var.mgmtHostPort}"
#     }
# }

# resource "template_file" "server_conf_master" {
#     template    = "${file("${path.module}/server_conf_master.tpl")}"
#     vars     {
#         replication_factor  = "${var.replication_factor}"
#         search_factor       = "${var.search_factor}"
#         pass4SymmKey        = "${var.pass4SymmKey}"
#     }
# }

# resource "template_file" "server_conf_indexer" {
#     template    = "${file("${path.module}/server_conf_indexer.tpl")}"
#     vars    {
#         mgmtHostPort        = "${var.mgmtHostPort}"
#         master_ip           = "${aws_instance.master.private_ip}"
#         pass4SymmKey        = "${var.pass4SymmKey}"
#         replication_port    = "${var.replication_port}"
#     }
# }

# resource "template_file" "user_data_master" {
#     template    = "${file("${path.module}/user_data.tpl")}"
#     vars    {
#         deploymentclient_conf_content   = <<EOF
#                                           [deployment-client]
#                                           serverRepositoryLocationPolicy = rejectAlways
#                                           repositoryLocation = \$SPLUNK_HOME/etc/master-apps
#                                           ${template_file.deploymentclient_conf.rendered}
#                                           EOF
#         server_conf_content             = "${template_file.server_conf_master.rendered}"
#         serverclass_conf_content        = ""
#         web_conf_content                = "${template_file.web_conf.rendered}"
#         role                            = "master"
#     }
# }

######################## Key Pair Part ###################

# resource "tls_private_key" "awskey" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "generatedkey" {
#   key_name   = "${var.key_name}"
#   public_key = "${tls_private_key.awskey.public_key_openssh}"
# }


####################### IAM Role###########################
data "aws_iam_policy_document" "splunk-node-policy" {
  statement {
    version = "2012-10-17"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "splunk-node-role" {
  name = "${var.name}-splunk-node-role"

  assume_role_policy = "${data.aws_iam_policy_document.splunk-node-policy.json}"

  tags = {
    name = "splunk-node-role"
  }
}

###################### IAM instance profile ###################
resource "aws_iam_instance_profile" "splunk-node-profile" {
  name = "${var.name}-splunk-node-profile"
  role = "${aws_iam_role.splunk-node-role.name}"
}



######################## Instace Part #####################
resource "aws_instance" "master" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type_indexer}"
  # key_name = "${aws_key_pair.generatedkey.key_name}"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.application-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.splunk-node.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.splunk-node-profile.name}"
  # user_data = "${template_file.user_data_master.rendered}"


  tags = {
    Name = "${var.name}master-node"
    Location = "Ahmedabad"
  }
}

resource "aws_instance" "deploymentserver" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type_indexer}"
  # key_name                    = "${var.key_name}"
  key_name = "${var.key_name}"
  subnet_id                   = "${aws_subnet.application-a.id}"
  # user_data                   = "${template_file.user_data_deploymentserver.rendered}"
  vpc_security_group_ids      = ["${aws_security_group.splunk-node.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.splunk-node-profile.name}"

  tags {
      Name = "${var.name}-splunk_deploymentserver"
  }
}

resource "aws_instance" "indexer" {
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type_indexer}"
  # key_name                    = "${var.key_name}"
  key_name = "${var.key_name}"
  subnet_id                   = "${aws_subnet.application-a.id}"
  # user_data                   = "${template_file.user_data_deploymentserver.rendered}"
  vpc_security_group_ids      = ["${aws_security_group.splunk-node.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.splunk-node-profile.name}"

  tags {
      Name = "${var.name}-indexer"
  }
}