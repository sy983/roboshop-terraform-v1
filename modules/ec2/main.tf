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
  count     = var.asg ? 1: 0
  name = "${var.name}-${var.env}-lt"
  image_id = data.aws_ami.rhel9.id
  instance_type =  var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data     =  base64encode(templatefile("${path.module}/userdata.sh" , {
    env         =  var.env
    role_name   =  var.name
    vault_token =  var.vault_token
  }))

  tags = {
    Name = "${var.name}-${var.env}-lt"
  }
}

resource "aws_autoscaling_group" "main" {
  count      = var.asg ? 1: 0
  name = "${var.name}-${var.env}-asg"
  desired_capacity    = var.capacity["desired"]
  max_size            = var.capacity["max"]
  min_size            = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.main.*.arn[count.index]]

  launch_template {
    id      = aws_launch_template.main.*.id[0]
    version = "$Latest"
  }
  tag  {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name}-${var.env}"
  }
}

resource "aws_instance" "main" {
  count         =  var.asg ? 0: 1
  ami           = data.aws_ami.rhel9.image_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data     = base64encode(templatefile("${path.module}/userdata.sh" , {
    env         =  var.env
    role_name   =  var.name
    vault_token =  var.vault_token

  }))
  tags = {
    Name = "${var.name}-${var.env}"
  }
}

resource "aws_route53_record" "instance" {
  count         =  var.asg ? 0: 1
  zone_id       = var.zone_id
  name          = "${var.name}-${var.env}"
  type          = "A"
  ttl           = 300
  records       = [aws_instance.main.*.private_ip[count.index]]
}

resource "aws_lb" "main" {
  count         =  var.asg ? 1: 0
  name               = "${var.name}-${var.env}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups =  [aws_security_group.load-balancer.*.id[count.index]]
  subnets            = var.lb_subnets_ids

  tags = {
    Environment = "${var.name}-${var.env}"

  }
}

resource "aws_lb_target_group" "main" {
  count         =  var.asg ? 1: 0
  name     = "${var.name}-${var.env}"
  port     = var.allow_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled =  true
    healthy_threshold =  2
    unhealthy_threshold = 2
    interval = 5
    path = "/health"
    timeout = 3
  }
}

resource "aws_lb_listener" "front_end" {
  count         =  var.asg ? 1: 0
  load_balancer_arn = aws_lb.main.*.arn[count.index]
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.*.arn[count.index]
  }
}

resource "aws_security_group" "load-balancer" {
  name        =  "${var.name}-${var.env}-alb-sg"
  description =  "${var.name}-${var.env}-alb-sg"
  vpc_id      =   var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.allow_lb_sg_cidr
  }

  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

resource "aws_route53_record" "lb" {
  count   = var.asg ? 1 : 0
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}"
  type    = "CNAME"
  ttl     = 10
  records = [aws_lb.main.*.dns_name[count.index]]
}

