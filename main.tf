provider "aws" {
  region  = var.region

}

terraform {
  
  backend "s3" {
  }
}

resource "aws_efs_file_system" "default" {
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  throughput_mode                 = var.throughput_mode
  tags                            = var.efs_mount_tags
}

resource "aws_efs_mount_target" "default" {
  count           =  length(var.subnets) > 0 ? length(var.subnets) : 0
  file_system_id  = join("", aws_efs_file_system.default.*.id)
  ip_address      = var.mount_target_ip_address
  subnet_id       = var.subnets[count.index]
  security_groups = [join("", aws_security_group.efs.*.id)]
}

## EFS Security Group ##
resource "aws_security_group" "efs" {
  name        = "Jenkins-efs-${var.environment}-sg"
  description = "EFS Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

## Jenkins Security Group ##
resource "aws_security_group" "jenkins" {
  name        = "Jenkins-server-${var.environment}-sg"
  description = "Jenkins Server Security Group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

## EFS Security Group rules##
resource "aws_security_group_rule" "efs_security_group_rule_01" {
  description              = "EFS access from Jenkins server"
  type                     = "ingress"
  from_port                = "2049" # NFS
  to_port                  = "2049"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins.id
  security_group_id        = join("", aws_security_group.efs.*.id)
}

resource "aws_security_group_rule" "efs_security_group_rule_02" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.efs.*.id)
}

## Jenkins Security Group rules ##
resource "aws_security_group_rule" "jenkins_security_group_rule_01" {
  description              = "EFS access from Jenkins server"
  type                     = "ingress"
  from_port                = "2049" # NFS
  to_port                  = "2049"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins.id
  security_group_id        = join("", aws_security_group.jenkins.*.id)
}

resource "aws_security_group_rule" "jenkins_security_group_rule_02" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.jenkins.*.id)
}

resource "aws_security_group_rule" "jenkins_security_group_rule_03" {
  description              = "HTTP Port for Jenkins server"
  type                     = "ingress"
  from_port                = "8080"
  to_port                  = "8080"
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = join("", aws_security_group.jenkins.*.id)
}

resource "aws_security_group_rule" "jenkins_security_group_rule_04" {
  description              = "HTTPS port for Jenkins server"
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = join("", aws_security_group.jenkins.*.id)
}

resource "aws_security_group_rule" "jenkins_security_group_rule_05" {
  description              = "SSH port for Jenkins server"
  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = join("", aws_security_group.jenkins.*.id)
}

resource "aws_instance" "jenkins" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  #iam_instance_profile   = var.iam_role
  
  user_data = <<-EOF
  #!/bin/bash
  echo "${aws_efs_file_system.default.dns_name}:/ /mnt nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" | sudo tee -a /etc/fstab
  echo export SERVER_ENVIRONMENT=${var.SERVER_ENV}  | sudo tee -a /etc/profile
  echo export AWS_REGION=${var.region} | sudo tee -a /etc/profile
  source /etc/profile
  sudo yum update -y
  sudo sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  sudo yum upgrade
  sudo amazon-linux-extras install java-openjdk11 -y
  sudo yum install jenkins -y
  sleep 200
  sudo mount -a
  sudo mkdir /mnt/jenkins
  sudo chown -R jenkins:jenkins /mnt/jenkins/
  sudo usermod -d /mnt/jenkins/ jenkins
  sudo systemctl enable jenkins
  sleep 10
  sudo sed 's/\/var\/lib\/jenkins/\/mnt\/jenkins/g' /etc/sysconfig/jenkins
  sudo sed -i 's/\/var\/lib\/jenkins/\/mnt\/jenkins/g' /usr/lib/systemd/system/jenkins.service
  sudo systemctl daemon-reload
  sleep 5
  sudo systemctl start jenkins
  EOF

  # 
  tags = {
   "Name" = "mm-jenkins-${var.SERVER_ENV}"
    "tr:appFamily" = "mm"
    "tr:appName" = "mm-jenkins-${var.SERVER_ENV}"
    "tr:environment-type" = var.SERVER_ENV
    "tr:role" = "jenkins-server"
    "ca:owner" = "mm-devops"
    #"cr:contact" = "mm-ipg-devops@clarivate.com"
    "product" = "Mark Monitor"
    "datadog" = "true"
    "env" = var.SERVER_ENV
    "patch" = "mm${var.SERVER_ENV}"
  }

  root_block_device {
    volume_size = 10
  }
  
  lifecycle {
    create_before_destroy = true
  }

  # provisioner "local-exec" {
  #   command = "aws ec2 wait instance-status-ok --instance-ids ${self.id}"
  # }
}
