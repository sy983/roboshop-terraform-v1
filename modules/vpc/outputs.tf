output "vpc_id" {
  value = "aws.vpc.main.id"
}


output "subnets" {
  value = tomap({
    "web" = aws_subnet.web.*.id
    "app" = aws_subnet.app.*.id
    "db" = aws_subnet.db.*.id
    "public" = aws_subnet.public.*.id

  })
}