terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  access_key = "Your access key here" 
  secret_key = "Your secret key here"
}

# Create Security Group (SG)
resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow inbound web traffic"

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    "Name" = "test-sg"
  }

}

#search for ubuntu image id
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# create 2 Instances (t2.micro) - with NGINX running on each
resource "aws_instance" "web" {
  count = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  # Use the user_data attribute to install the NGINX upon creation
  user_data = "${file("install_nginx.sh")}"
  vpc_security_group_ids  = [ aws_security_group.allow_web.id]
  tags = {
    Name = "webserver-${count.index + 1}"
  }
}


resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#create target group
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

# attach instances to target group
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.web[0].id
  port             = 80
}
resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.web[1].id
  port             = 80
}

# get subnet ids in the default VPC
data "aws_subnet_ids" "this" {
  vpc_id = aws_default_vpc.default.id


}

# create Application load balancer
resource "aws_lb" "test-alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = data.aws_subnet_ids.this.ids

  enable_deletion_protection = true


  tags = {
    Name = "my-test-alb"
  }
}

# add listener to ALB and set the action to forward to the target group we've created .
resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = "${aws_lb.test-alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.test.arn}"
  }
}