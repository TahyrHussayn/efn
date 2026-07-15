output "elastic_ip" {
  value       = aws_eip.efn.public_ip
  description = "Point your Cloudflare DNS A record to this IP"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Hardcode this value as 'role-to-assume' in your .github/workflows/deploy.yml file"
}
