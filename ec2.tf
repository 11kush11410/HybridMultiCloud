variable "my_ec2_type" {}

resource "aws_instance" "wordpress_os" {
  ami           = "ami-096117f36bb3ddec8"
  instance_type = var.my_ec2_type
  key_name =  aws_key_pair.instance_key.key_name
  availability_zone="ap-south-1a"
  vpc_security_group_ids = [ aws_security_group.SG1.id ]
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "Wordpress_OS"
  }
}

resource "aws_instance" "mysql_os" {
  ami           = "ami-0e4c4d2ce50a05c3e"
  instance_type = var.my_ec2_type
  key_name =  aws_key_pair.instance_key.key_name
  associate_public_ip_address = true 
  availability_zone="ap-south-1b"
  vpc_security_group_ids = [ aws_security_group.SG2.id ]
  subnet_id =  aws_subnet.private_subnet.id
  tags = {
    Name = "MySql_os"
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-0732b62d310b80e97"
  instance_type = var.my_ec2_type
  key_name =  aws_key_pair.instance_key.key_name
  availability_zone="ap-south-1a"
  vpc_security_group_ids = [ aws_security_group.SG3.id ]
  subnet_id =  aws_subnet.public_subnet.id
  tags = {
    Name = "Bastion_os"
  }
}
