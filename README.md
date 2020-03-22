# Headless Factorio server

Terraform modules to provision a headless Factorio server in AWS, with save game
backups to S3.

## Quick start

### Requirements

* [Terraform](https://www.terraform.io) version 0.12.x
* Amazon AWS account and [access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)

### Initial setup

* Put AWS credentials in `~/.aws/credentials` (`aws_access_key_id` and
  `aws_secret_access_key`)

* Configure and create stateful infrastructure:

      cd state/
      terraform init && terraform apply
      terraform output
      
      # Take note of bucket name in output
      bucket_name = factorio-20190602222917314000000001

* Configure stateless infrastructure:

      cd instance/
      terraform init
    
      # Add correct bucket_name from above
      vim terraform.tfvars

* Configure Factorio server (see [Setting up a Linux Factorio server](https://wiki.factorio.com/Multiplayer#Setting_up_a_Linux_Factorio_server)):

      vim conf/server-settings.json

### Game server

Create stateless infrastructure:

    cd instance/
    terraform apply
    terraform output
    
    # Public IP of the game server
    ip = 3.121.142.76

The game server is automatically started and the most recent save games from S3
are restored onto the instance.

Destroy infrastructure after use:

    cd instance/
    terraform destroy

This will automatically backup the save games to the specified S3 bucket.

## Details

* `state/` contains the Terraform module for the stateful server infrastructure.
  This includes the S3 bucket holding game state inbetween games, i.e. while the
  server instance does not exist.
* `instance/` contains the Terraform module for the stateless server
  infrastructure. This includes the EC2 instance that runs the game server.

### Services

Several systemd services are provisioned to the server instance:

* `factorio-headless.service`: Service to start/stop the headless game server.
* `factorio-restore.service`: One shot service that restores save games from S3.
* `factorio-backup.service`: One shot service that backs up save games to S3.

You can use the `connect.sh` script to connect to the game server via SSH.

### Limitations

Currently there is no support for creating a fresh game, just for loading existing
save games. The headless Factorio server expects the `--create FILE` argument to
create a game. The workaround is to create a game locally, export the save game,
and use that.

This provisioning code populates `--start-server FILE` (to load a named save game) or
`-start-server-load-latest` (to load the latest save game), depending on whether
the `factorio_save_game` variable is set.
