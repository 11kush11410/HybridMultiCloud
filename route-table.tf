resource "aws_route_table" "gw_route" {
  vpc_id = "${aws_vpc.MINEVPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_int_gw.id}"
  }

  tags = {
    Name = "gw_route"
  }
}
