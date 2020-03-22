output "ip" {
  value       = aws_instance.factorio.public_ip
  description = "The public IP address of the server instance."
}

output "ssh_private_key" {
  value       = tls_private_key.ssh.private_key_pem
  description = "The private SSH key to connect to the server instance."
  sensitive   = true
}
