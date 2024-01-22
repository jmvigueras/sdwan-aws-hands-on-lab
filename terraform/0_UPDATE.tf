#-----------------------------------------------------------------------------------------------------
# FortiGate Terraform deployment
# Active Passive High Availability MultiAZ with AWS Transit Gateway with VPC standard attachment
#-----------------------------------------------------------------------------------------------------
locals {
  #-----------------------------------------------------------------------------------------------------
  # IMPORTANT: UPDATE variables with data provided in lab portal
  #-----------------------------------------------------------------------------------------------------
  # Unique User ID
  user_id = "aws-eu-west-1-user-0"

  # Region and Availability Zone where deploy VPC and Subnets
  region = "eu-west-1"

  # CIDR range to use for your VCP: 10.1.x.x group 1 - 10.1.1.0/24 user-1
  user_vpc_cidr = "10.1.0.0/24"

  # Lab token (update with lab token received by email)
  externalid_token = "xxxxxxx"

  # AWS account_id
  account_id = "04xxxx"
}