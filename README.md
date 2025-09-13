# Remote Lab

This is my remote lab.

## Guide:

### Step 1: Configure the backend

### Step 2: Create VPN secrets

This configuration expects a secret called `/vpn/wg-private-key`. This is the private key associated with the public key found in ./services/vpn/configuration.nix. You will need to change the configuration.nix to have your public key and go into the AWS console and create your private key secret.

### Step 3: Configure AIM

Create security group for VPN. This can be done by commenting out the services in the services/vpn/main.tf. It is required that this group exists before we create the VPN AMI.

### Todo:

- immich, syncthing

### Routes:

## Notes:

### ECS/EC2 roles

- For EC2 instances: An EC2 instance can only have one instance profile attached at a time, and that instance profile points to a single IAM role. This role defines what the EC2 instance itself can do.
- For ECS Fargate: Fargate instances (the underlying compute) are managed by AWS, and you don't directly attach an instance profile or role to them in the same way you do with EC2. Instead, in Fargate, you define two distinct types of roles for your tasks:
  - Task Execution Role: This role grants the ECS service permissions to perform actions on behalf of your task, such as pulling images and pushing logs.
  - Task Role: This role grants permissions to the application running inside your container to make AWS API calls (e.g., read from S3, write to DynamoDB).
