
resource "tls_private_key" "kb" {
  algorithm   = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "instance_key" {
  key_name   = "securekey"
  public_key =  tls_private_key.kb.public_key_openssh 

}

resource "local_file" "mykeyfile" {
    content     = tls_private_key.kb.private_key_pem 
    filename =  "securekey.pem"
}
