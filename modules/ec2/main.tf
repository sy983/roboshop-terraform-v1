resource "aws_security_group" "allow_tls" {
  name        =  "${var.name}-${var.env}-sg"
  description =  "${var.name}-${var.env}-sg"
  vpc_id      =   var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_nodes
  }

  ingress {
    from_port        = var.allow_port
    to_port          = var.allow_port
    protocol         = "tcp"
    cidr_blocks      = var.allow_sg_cidr
  }

  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}


resource "aws_launch_template" "main" {
  name = "${var.name}-${var.env}-lt"
  image_id = data.aws_ami.rhel9.id
  instance_type =  var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  tags = {
    Name = "${var.name}-${var.env}-lt"
  }

  }

resource "aws_autoscaling_group" "main" {
  name = "${var.name}-${var.env}-asg"
  desired_capacity   = var.capacity["desired"]
  max_size           = var.capacity["max"]
  min_size           = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}