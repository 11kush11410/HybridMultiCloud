
resource "aws_vpc" "MINEVPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "MINEVPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.MINEVPC.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone="ap-south-1a"
  map_public_ip_on_launch = "true" 

  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.MINEVPC.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone="ap-south-1b"
  

  tags = {
    Name = "Private_Subnet"
  }
}
