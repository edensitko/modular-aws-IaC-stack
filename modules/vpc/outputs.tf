output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public-a.id,
    aws_subnet.public-b.id
  ]
}
  