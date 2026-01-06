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
  public_key = file("/home/cloudshell-user/.ssh/asbah_key.pub")
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
