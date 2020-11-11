# create the SSH bastion server, along with an EIP and SG
data "aws_ami" "ubuntu" {
	most_recent = true

	filter {
		name   = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
	}

	filter {
		name   = "virtualization-type"
		values = ["hvm"]
	}

	owners = ["099720109477"] # Canonical
}

# SSH bastion
resource "aws_instance" "bastion" {
	ami           = data.aws_ami.ubuntu.id
	instance_type = "t3a.nano"

	vpc_security_group_ids = [aws_security_group.bastion.id]
	key_name = "web-server-demo-dev"

	# needs a public IP for ssh access
	associate_public_ip_address = true

	# use the first public subnet in the VPC
	subnet_id = module.vpc.public_subnets.0

	tags = merge(var.common_tags,
			{
				role = "SSH bastion",
				Name = "ssh-bastion-dev"
			}
		)
	}

# allocate stable EIP
resource "aws_eip" "bastion" {
	instance = aws_instance.bastion.id
	tags = merge(var.common_tags,
			{
				role = "EIP for SSH bastion"
			}
		)
}

resource "aws_security_group" "bastion" {
	name = "ssh-bastion-sg"
	description = "SG for bastion"
	vpc_id = module.vpc.vpc_id
	tags = merge(var.common_tags,
			{
				role = "SG for SSH bastion"
			}
		)
}

resource "aws_security_group_rule" "bastion-ingress" {
	type              = "ingress"
	description		  = "allow ingress to bastion on all tcp from allowed CIDRs"
	from_port         = 0
	to_port           = 65535
	protocol          = "tcp"
	cidr_blocks       = var.vpc_default_ingress_cidr_blocks
	security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion-egress" {
	type              = "egress"
	description		  = "allow egress to ALL"
	from_port         = 0
	to_port           = 0
	protocol          = "-1"
	cidr_blocks       = ["0.0.0.0/0"]
	security_group_id = aws_security_group.bastion.id
}

