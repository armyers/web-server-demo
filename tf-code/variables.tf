# variables for the web server demo VPC
variable "vpc_name" {
	type = string
	default = "web-server-DEV"
}

variable "vpc_cidr" {
	type = string
	default = "10.0.0.0/16"
}

variable "vpc_azs" {
	type = list(string)
	
	default = [
		"us-west-2a",
		"us-west-2b",
		"us-west-2c"
	]
}

variable "vpc_priv_subnets" {
	type = list(string)
	
	default = [
		"10.0.1.0/24",
		"10.0.2.0/24",
		"10.0.3.0/24"
	]
}

variable "vpc_pub_subnets" {
	type = list(string)
	
	default = [
		"10.0.128.0/24",
		"10.0.129.0/24",
		"10.0.130.0/24"
	]
}

variable "instance_type" {
    type = string
    default = "t3a.nano"
}

variable common_tags {
	type = map

	default = {
        provisioned = "terraform"
        environment = "DEV"
        owner = "allen-myers"
        purpose = "web-server demo"
    }
}

variable vpc_default_ingress_cidr_blocks {
    type = list(string)
    description = "list of CIDRs"
    default = ["162.233.202.169/32"]
}
