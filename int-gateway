
resource "aws_internet_gateway" "vpc_int_gw" {
  vpc_id = "${aws_vpc.MINEVPC.id}"

  tags = {
    Name = "VPC_internet_gw"
  }
}
