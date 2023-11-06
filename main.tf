# Define the provider and region
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet within the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1b"  # Change to your desired availability zone
}

# Create a security group for the EC2 instance
resource "aws_security_group" "my_security_group" {
  name_prefix = "my-ec2-sg"

  # Define inbound rules to allow SSH (port 22) and HTTP (port 80) traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch an EC2 instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # Replace with your desired AMI ID
  instance_type = "t2.micro"               # Replace with your desired instance type
  subnet_id     = aws_subnet.my_subnet.id
  key_name      = "hello"             # Replace with your SSH key pair
  security_groups = [aws_security_group.my_security_group.name]

  user_data = <<-EOF
              #!/bin/bash
              yum -y update
              yum -y install httpd
              service httpd start
              yum -y install wget
              wget -P /var/www/html https://eng21ct0016.github.io/TechTidy/index.html
              chmod -R 755 /var/www/html
              service httpd restart
              EOF
}

provisioner "remote-exec" {
  inline = [
    "chmod -R 755 /var/www/html",
    "service httpd restart"
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"  # Update with the correct username for your AMI
    host = self.public_ip  # This references the public IP of the EC2 instance
  }
}

# Output the public IP of the EC2 instance (optional)
output "public_ip" {
  value = aws_instance.my_ec2.public_ip
}
