
terraform {
  backend "s3" {
    bucket         = "asbah-terraform-state-2026" # Must match bucket name above
    key            = "dev/postgres/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}


provider "aws" {
  region = "eu-north-1"
}

# 1. Dynamically find the latest RHEL 9 AMI
data "aws_ami" "rhel_9" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat Owner ID

  filter {
    name   = "name"
    values = ["RHEL-9.4.0_HVM-*-x86_64-*-Hourly2-GP3"]
  }
}

# 2. Upload your SSH Public Key (V2 to avoid "Already Exists" error)
resource "aws_key_pair" "asbah_key_v2" {
  key_name   = "asbah-key-v2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEdiKyLvuZYj3vCwWktnwvwQiNch0k+dN/5L4JP1aVCTInT0SZykJd1quT64vz7Mj+wqYas+X93j/JEZWNKvqW+wd5zpK3F7NZe6JOe5B/BOvM185DJls6JJt2EQIJuXPiDa2wlVQfy2UaK3rhmTdEJ9I0XaPYAlpP2NN62cN/nNqzo0DCkKAiaocL5lCBav/1oyoQAEBYhF7SILvngl1dhzSp4lqbLFwCcRwpRd8i1uJu/Bhx2hTwvXemFHFRNAXal3+z2op821Sb8M0MLXrShcUHLgxWvemgOX8YHmPNQXYSeJzsST8xk8JMntpgaQJtBeet54SfajuePmWk/4TpiUpCUw5i+TrO9WTLwjbB2heSgxAa4QPgWOXKdkOvJRFEfYKc/ej7BLvRjUXfbhWpKLFoFTu5uJ0AWi0gdp/lsA5WKEFW0TkFld3lJibsxAwy5IpjKEI0tVFNzWfwj7IYoOhFi8gcXbfsHWvG1y9Exv2JxzicRBBuT5a9glflAkcMPDMqcMHz763LePlXGzkVLAEZ/mLRyjFc9ljuPr4osFDjLnQgl8bbJSiSoP73ENVHLum+L7sb+ZwWQJfxIRWAPvCE0oGAaXno/irlQhekkgo1l6PwPAia3C6uyjNOkO3l3MKcGz8OrBmdQX1KpPzUgDIKqP0uDtKAmqsLPY4V3Q== cloudshell-user@ip-10-133-34-43.eu-north-1.compute.internal"


}

# 3. Security Group with Monitoring & DB Ports
resource "aws_security_group" "db_sg_v2" {
  name        = "asbah-db-security-group-v2"
  description = "Security group for Postgres and Monitoring"

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL Access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter (Monitoring) Access
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. The EC2 Instance
resource "aws_instance" "asbah_db_server_v2" {
  ami           = data.aws_ami.rhel_9.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.asbah_key_v2.key_name
  vpc_security_group_ids = [aws_security_group.db_sg_v2.id]

root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  tags = {
    Name = "Asbah-Postgres-Production"
  }

}

# 5. Output for Ansible
output "server_public_ip" {
  value = aws_instance.asbah_db_server_v2.public_ip
}
