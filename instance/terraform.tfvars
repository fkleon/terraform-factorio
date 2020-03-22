# Factorio server version
factorio_version = "0.18.15"
# Factorio save game
#factorio_save_game = "Zocken"

# Factorio server instance: NVMe instance
#instance_type = "c5.large"
# Internal device name specific to NVMe
#ebs_device_name_int = "/dev/nvme1n1"

# S3 bucker for save games. Use bucket name from state module.
bucket_name = "factorio-123"

# AWS SSH keypair. Sorry, RSA only.
# The public key part is used to create the server instance.
ssh_public_key = "ssh-rsa YOUR-PUBKEY"
# The private key part is used to provision the instance.
ssh_private_key = <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
YOUR-PRIVKEY
-----END OPENSSH PRIVATE KEY-----
EOF
