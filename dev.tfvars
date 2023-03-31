########## Instance Variables #############
region  = "us-west-2"
key_name = "mm5-test"
instance_count = 1
instance_type = "t2.xlarge"
iam_role ="install_d5_software"
subnet_id = "subnet-05e7f560"
environment = "dev"
security_group = ["sg-02f7d6e6fe0413851", "sg-0b893840c00b86ebf", "sg-00bed7afcc9b48e27"]

########### EFS, VPC and Subnet Variables #########################
vpc_id = "vpc-f4262991"
subnets = ["subnet-05e7f560", "subnet-438abd34", "subnet-27f3bf7e"]

########### Load Balancer Variables #########################
alb_subnets = ["subnet-05e7f560", "subnet-438abd34", "subnet-27f3bf7e"]
alb_security_groups = ["sg-d9da37be"]
load_balancer_type = "application"
