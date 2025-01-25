resource "aws_security_group" "main" {
  name        =  "${var.name}-${var.env}-sg"
  description =  "${var.name}-${var.env}-sg"
  vpc_id      =   "var.vpc_id"

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
  vpc_security_group_ids = [aws_security_group.main.id]
  tags = {
    Name = "${var.name}-${var.env}-lt"
  }

  }
