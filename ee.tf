provider  "aws" {
region  = "ap-south-1"
profile = "fsociety"
}


resource "tls_private_key" "aliatin_key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}



resource "local_file" "kingston" {
    filename = "rockon.pem"
}


resource "aws_key_pair" "aliatin_key" {
  key_name   = "rockon"
  public_key = tls_private_key.aliatin_key.public_key_openssh  
}



resource "aws_instance"  "aliatin" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name	=  aws_key_pair.aliatin_key.key_name
  security_groups =  [ "task11-sg" ] 
  
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.aliatin_key.private_key_pem
    host     = aws_instance.aliatin.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  } 

tags = {
    Name = "LinuxWorld"
  }
}

output  "myout11" {

value = aws_instance.aliatin.availability_zone

}



resource "aws_security_group"  "task11-sg" {
 
name = "task11-sg"
  
description = "Allow TCP inbound traffic"
  
vpc_id = "vpc-87fee3ef"


  

ingress {
   
description = "SSH"
    
from_port = 22
   
to_port = 22
  
protocol  = "tcp"
    
cidr_blocks = [ "0.0.0.0/0" ]
  
}

  

ingress {
    
description = "HTTP"
    
from_port = 80
    
to_port = 80
    
protocol = "tcp"
    
cidr_blocks = [ "0.0.0.0/0" ]
  
}

  

egress {
    
from_port = 0
    
to_port = 0
    
protocol = "-1"
    
cidr_blocks = ["0.0.0.0/0"]
  
}

  

tags = {
    
Name = "task11-sg"
  
}
}



resource "aws_ebs_volume" "volume11" {
  availability_zone = aws_instance.aliatin.availability_zone
  size              = 3

    tags = {
    Name = "mynewvolume"
  }
}
 



resource "aws_volume_attachment" "ebsattch" {
  
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.volume11.id
  instance_id = aws_instance.aliatin.id
  force_detach = true
} 



output "mine_ebss12" {
value = aws_ebs_volume.volume11.id
}

output "mineos_ip" {
value = aws_instance.aliatin.public_ip
}


resource "null_resource" "localnull888"  {
	
provisioner "local-exec" {
	    
command = "echo  ${aws_instance.aliatin.public_ip}  > mypublicip.txt"
  	
}

}



resource "null_resource" "remotenull444" {

depends_on = [

aws_volume_attachment.ebsattch,
]

connection {
    
type     = "ssh"
    
user     = "ec2-user"
    
private_key = tls_private_key.aliatin_key.private_key_pem
host     = aws_instance.aliatin.public_ip
  
}

provisioner "remote-exec" {
    
inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      
"sudo mount  /dev/xvdh  /var/www/html",
      
"sudo rm -rf /var/www/html/*",
      
"sudo git clone https://github.com/11kush11410/mockingbird.git   /var/www/html/"
   
 ]
  
}

}





//------------------------------------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "creature3ddd" {
  bucket = "creature3ddd"
  acl     = "public-read"

 provisioner "local-exec" {
        command     = "git clone https://github.com/11kush11410/mockingbird  bonz"
    }

provisioner "local-exec" {
        when        =   destroy
        command     =   "echo Y | rmdir /s  bonz"
    }

}

resource "aws_s3_bucket_object" "image-pull"{

bucket  = aws_s3_bucket.creature3ddd.bucket
key     = "effect.jpg"
source  = "bonz/ibm-red-hat-leadspace.png"
acl     = "public-read"

}

//-----------------------------------------------------------------------------------------------------------------------------//

//cloud front



locals {
  
s3_origin_id = aws_s3_bucket.creature3ddd.bucket
  
image_url = "${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.image-pull.key}"

}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.creature3ddd.bucket_regional_domain_name 
    origin_id   = local.s3_origin_id 

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E294Y4AS6PCHVM" 
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.php" 


default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }


viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

viewer_certificate {
    cloudfront_default_certificate = true
  }

connection {
    
type     = "ssh"
    
user     = "ec2-user"
    
private_key = tls_private_key.aliatin_key.private_key_pem
host     = aws_instance.aliatin.public_ip
  
}

provisioner "remote-exec" {
        inline  = [
            "sudo su << EOF",
            "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.image-pull.key}'>\" >> /var/www/html/index.php",
            "EOF"
        ]
    }

}




resource "null_resource" "localnull222"  {

depends_on = [
    
aws_cloudfront_distribution.s3_distribution,
 ]

	
provisioner "local-exec" {
	    
command = "start chrome  ${aws_instance.aliatin.public_ip}"
  	
}

}



