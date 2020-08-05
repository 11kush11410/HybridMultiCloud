resource "aws_eip" "kb" {
  vpc      = true
}

resource "aws_nat_gateway" "gw_nat" {
  allocation_id = "${aws_eip.kb.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"
  depends_on    = [ "aws_internet_gateway.vpc_int_gw" ]
}

resource "aws_route_table" "nat-rtable" {
  vpc_id = "${aws_vpc.MINEVPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw_nat.id}"
  }
  tags = {
    Name = "my-nat-routetable"
  }
}

