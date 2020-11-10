module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "2.64.0"

    name = var.vpc_name
    cidr = var.vpc_cidr
    azs = var.vpc_azs
    private_subnets = var.vpc_priv_subnets
    public_subnets  = var.vpc_pub_subnets

    # setup the NAT gateways, but they will use stable EIPs via a resource external to this module
    enable_nat_gateway = true
    single_nat_gateway = false
    reuse_nat_ips       = true
    external_nat_ip_ids = aws_eip.nat.*.id

    # not using a vpn gateway
    enable_vpn_gateway = false

    manage_default_security_group = true
    default_security_group_name = "${var.vpc_name}-default-sg"
    default_security_group_ingress = [
        {
            cidr_blocks      = join(",", var.vpc_default_ingress_cidr_blocks)
            description      = "HTTP access"
            from_port        = "80"
            to_port          = "80"
            protocol         = "6"
        },
        {
            cidr_blocks      = join(",", var.vpc_default_ingress_cidr_blocks)
            description      = "HTTPS access"
            from_port        = "443"
            to_port          = "443"
            protocol         = "6"
        }
    ]

    # default to egress to ALL
    default_security_group_egress = [
        {
            cidr_blocks      = "0.0.0.0/0"
            description      = "egress to ALL"
            protocol         = "-1"
        }
    ]

    tags = var.common_tags
}

# allocate stable EIPs for the nat gateways of the VPC
resource "aws_eip" "nat" {
    count = 3

    vpc = true
    tags = var.common_tags
}


