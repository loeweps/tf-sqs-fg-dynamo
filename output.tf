output "alb_url" {
  value = "http://${aws_alb.sun_api.dns_name}"
}
