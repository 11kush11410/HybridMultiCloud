provider "aws" {
    region = "ap-south-1"
    profile = "kushg"
}


resource "tls_private_key" "aliatin_key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}


resource "local_file" "kingston" {
    content = tls_private_key.aliatin_key.private_key_pem
    filename = "rockon.pem"
	file_permission = 0400
}


resource "aws_key_pair" "aliatin_key" {
  key_name   = "rockon"
  public_key = tls_private_key.aliatin_key.public_key_openssh  
}


resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.5.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}


resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.5.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "subnet1"
  }
}


resource "aws_internet_gateway" "int_gw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "int_gw"
  }
}


resource "aws_route_table" "gw_route" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gw.id
  }

  tags = {
    Name = "gw_route"
  }
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.gw_route.id
}



resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow Inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "Allow NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}


resource "aws_efs_file_system" "efs-vol" {
  creation_token = "efs"
  performance_mode="generalPurpose"
  tags = {
    Name = "efs-vol"
  }
}


resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.efs-vol.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs-policy-wizard-37ea40d1-826a-4398-99d6-a4561182f9f6",
    "Statement": [
        {
            "Sid": "efs-statement-65263caf-dba3-4299-b808-4da9635bba63",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.efs-vol.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:ClientRootAccess"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}


resource "aws_efs_mount_target" "gama" {
  file_system_id = aws_efs_file_system.efs-vol.id
  subnet_id      = aws_subnet.subnet1.id
  security_groups = [ "${aws_security_group.sg.id}" ]
}


resource "aws_instance"  "aliatin" {
depends_on = [
    aws_efs_mount_target.gama,
  ] 
    ami = "ami-00b494a3f139ba61f"
    instance_type = "t2.micro"
	associate_public_ip_address = true
	availability_zone = "ap-south-1a"
	subnet_id     = aws_subnet.subnet1.id
    key_name =  aws_key_pair.aliatin_key.key_name
    vpc_security_group_ids =  [ "${aws_security_group.sg.id}" ] 
	
 tags = {
    Name = "aliatin"
  }
}
resource "null_resource" "null_vol_attach"  {
depends_on = [
    aws_instance.aliatin,
  ]
  
connection {
    type = "ssh"
    user = "ec2-user"
    private_key = tls_private_key.aliatin_key.private_key_pem
    host = aws_instance.aliatin.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo yum install -y httpd git php amazon-efs-utils nfs-utils",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo chmod ugo+rw /etc/fstab",
      "sudo echo '${aws_efs_file_system.efs-vol.id}:/ /var/www/html efs tls,_netdev' >> /etc/fstab",
      "sudo mount -a -t efs,nfs4 defaults",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/11kush11410/mockingbird.git   /var/www/html/"
    ]
  }
 	
}


resource "aws_s3_bucket" "creature3ddd" {
  bucket = "creature3ddd"
  acl = "public-read"

  provisioner "local-exec" {
      command = "git clone https://github.com/11kush11410/mockingbird  bonz"
    }
  provisioner "local-exec" {
      when = destroy
      command = "echo Y | rmdir /s bonz"
    }

depends_on = [
   null_resource.null_vol_attach,
  ]	
	
}


resource "aws_s3_bucket_object" "image-pull" {
    bucket = aws_s3_bucket.creature3ddd.bucket
    key = "effect.jpg"
    source = "bonz/ibm-red-hat-leadspace.png"
    acl = "public-read"	
}


locals {
    s3_origin_id = aws_s3_bucket.creature3ddd.bucket
    image_url = "${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.image-pull.key}"
}


resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Sync CloudFront to S3"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
    origin {
        domain_name = aws_s3_bucket.creature3ddd.bucket_regional_domain_name
        origin_id = local.s3_origin_id


    s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
      } 
    }
	   
    enabled = true
    is_ipv6_enabled = true
    default_root_object = "index.php"

    custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/ibm-red-hat-leadspace.png"
    }

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id

    forwarded_values {
        query_string = false
    cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all" 
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    
	restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }	
	
	viewer_certificate {
        cloudfront_default_certificate = true
      }

    tags = {
        Name = "Web-CF-Distribution"
      }

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = tls_private_key.aliatin_key.private_key_pem 
        host = aws_instance.aliatin.public_ip
     }

    provisioner "remote-exec" {
        inline  = [
            "sudo su << EOF",
			"sudo chmod ugo+rw /var/www/html/",
            "echo \"<img src='http://${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.image-pull.key}'>\" >> /var/www/html/index.php",
            "EOF"
          ]
      }
   }

output "cloudfront_ip_addr" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}


resource "null_resource" "save_key_pair"  {
	provisioner "local-exec" {
	    command = "echo  '${tls_private_key.aliatin_key.private_key_pem}' > key.pem"
  	}
}


resource "null_resource" "slim-shady"  {
    depends_on = [
    aws_cloudfront_distribution.s3_distribution,
   ]

    provisioner "local-exec" {
        command = "start chrome  ${aws_instance.aliatin.public_ip}"
      }
 }
