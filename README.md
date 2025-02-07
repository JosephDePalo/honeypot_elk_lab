# Honey Pot & Elastic Stack Lab

This repository hosts the code for a lab where I set up and configure the Elastic Stack 
and the Cowrie honey pot on AWS infrastructure provisioned by Terraform. The lab write up can be found on [my personal website here](https://josephdepalo.com/honeypot-elastic-stack/).

## Usage

This repository contains the Terraform file used to provide all infrastructure. The below steps for using it assume you have an AWS account and AWS CLI is configured properly. See [this article](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) for information on setting up 

1. Provision an SSH key pair with `aws ec2 create-key-pair --key-name honey_net --query 'KeyMaterial' --output text > honey_net.pem` and set correct permissions for the private key with `chmod 400 honey_net.pem`.
2. Clone the git repository and `cd` into it.
3. Initialize Terraform with `terraform init`.
4. Provision the infrastructure with `terraform apply`.
5. When finished with the lab, destroy the provisioned infrastructure with `terraform destroy`.
