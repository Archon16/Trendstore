# Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# ========== VPC ==========
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "trend-vpc"
  }
}

# ========== SUBNET ==========
resource "aws_subnet" "trend_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-subnet"
  }
}

# ========== INTERNET GATEWAY ==========
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id

  tags = {
    Name = "trend-igw"
  }
}

# ========== ROUTE TABLE ==========
resource "aws_route_table" "trend_rt" {
  vpc_id = aws_vpc.trend_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trend_igw.id
  }

  tags = {
    Name = "trend-route-table"
  }
}

resource "aws_route_table_association" "trend_rta" {
  subnet_id      = aws_subnet.trend_subnet.id
  route_table_id = aws_route_table.trend_rt.id
}

# ========== SECURITY GROUP ==========
resource "aws_security_group" "trend_sg" {
  name        = "trend-sg"
  description = "Allow SSH, HTTP, Jenkins"
  vpc_id      = aws_vpc.trend_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App Port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "trend-sg"
  }
}

# ========== IAM ROLE FOR EC2 ==========
resource "aws_iam_role" "trend_ec2_role" {
  name = "trend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "trend-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "trend_ec2_policy" {
  role       = aws_iam_role.trend_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "trend_ec2_profile" {
  name = "trend-ec2-profile"
  role = aws_iam_role.trend_ec2_role.name
}

# ========== EC2 INSTANCE WITH JENKINS ==========
resource "aws_instance" "trend_jenkins" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.trend_subnet.id
  vpc_security_group_ids = [aws_security_group.trend_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.trend_ec2_profile.name
  key_name               = "firstkey"

user_data = <<-EOF
    #!/bin/bash
    yum update -y

    # Install Java 17
    yum install -y java-17-amazon-corretto

    # Install Jenkins
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    systemctl start jenkins
    systemctl enable jenkins

    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker jenkins

    # Install Git
    yum install -y git
  EOF

  tags = {
    Name = "trend-jenkins-server"
  }
}

# ========== OUTPUTS ==========
output "jenkins_public_ip" {
  value       = aws_instance.trend_jenkins.public_ip
  description = "Jenkins Server Public IP"
}

output "jenkins_url" {
  value       = "http://${aws_instance.trend_jenkins.public_ip}:8080"
  description = "Jenkins URL"
}

output "vpc_id" {
  value = aws_vpc.trend_vpc.id
}