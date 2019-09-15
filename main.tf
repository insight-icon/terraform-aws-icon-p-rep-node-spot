data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

locals {
  name = var.resource_group
  common_tags = {
    "Name" = local.name
    "Terraform" = true
    "Environment" = var.environment
  }

  tags = merge(var.tags, local.common_tags)

  command = format("aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids %s && aws ec2 describe-spot-instance-requests --spot-instance-request-ids %s | jq -r '.SpotInstanceRequests[].InstanceId'", aws_spot_instance_request.this.*.id[0], aws_spot_instance_request.this.*.id[0])
  command_chomped = chomp(local.command)
  command_when_destroy_chomped = chomp(var.command_when_destroy)
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "099720109477"]
  # Canonical
}

resource "aws_eip" "this" {
  vpc = true
  lifecycle {
    prevent_destroy = "false"
  }
}

resource "aws_eip_association" "this" {
  allocation_id = aws_eip.this.id
//  instance_id = module.instance_id.stdout
  instance_id = chomp(null_resource.contents.triggers["stdout"])
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.azs[0]
  size = var.ebs_volume_size
  type = "gp2"
  tags = merge(
  local.tags,
  {
    Name = "ebs-main"
  },
  )

  lifecycle {
    prevent_destroy = "false"
  }
}

resource "aws_volume_attachment" "this" {
  device_name = var.volume_path

  volume_id = aws_ebs_volume.this.id
//  instance_id = module.instance_id.stdout
  instance_id = chomp(null_resource.contents.triggers["stdout"])

  force_detach = true
}

data "template_file" "user_data" {
  template = file("${path.module}/data/user_data_ubuntu_ebs.sh")

  vars = {
    log_config_bucket = var.log_config_bucket
    log_config_key = var.log_config_key
  }
}


resource "aws_spot_instance_request" "this" {
  wait_for_fulfillment = true

  spot_price = var.spot_price

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  user_data = data.template_file.user_data.rendered
  key_name = var.key_name

  iam_instance_profile = var.instance_profile_id
  subnet_id = var.subnet_id
  security_groups = var.security_groups

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
    delete_on_termination = true
  }
}

//module "instance_id" {
//  source = "matti/resource/shell"
//  command = format("aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids %s && aws ec2 describe-spot-instance-requests --spot-instance-request-ids %s | jq -r '.SpotInstanceRequests[].InstanceId'", aws_spot_instance_request.this.*.id[0], aws_spot_instance_request.this.*.id[0])
//}

resource "null_resource" "wait_on_startup" {
  //This will fail on windows as it has a different sleep command - USE WSL ALWAYS
  provisioner "local-exec" {
    command = "sleep 20"
  }
  depends_on = [aws_spot_instance_request.this]
}

resource "null_resource" "start" {
  triggers = {
    depends_id = var.depends_id
  }
}


resource "null_resource" "shell" {
  triggers = {
    string = var.trigger
  }

  provisioner "local-exec" {
    command = "${local.command_chomped} 2>\"${path.module}/stderr.${null_resource.start.id}\" >\"${path.module}/stdout.${null_resource.start.id}\"; echo $? >\"${path.module}/exitstatus.${null_resource.start.id}\""
  }

  provisioner "local-exec" {
    when = destroy
    command = local.command_when_destroy_chomped == "" ? ":" : local.command_when_destroy_chomped
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm \"${path.module}/stdout.${null_resource.start.id}\""
    on_failure = continue
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm \"${path.module}/stderr.${null_resource.start.id}\""
    on_failure = continue
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm \"${path.module}/exitstatus.${null_resource.start.id}\""
    on_failure = continue
  }

  depends_on = [null_resource.wait_on_startup]
}

data "external" "stdout" {
  depends_on = [
    null_resource.shell]
  program = [
    "sh",
    "${path.module}/read.sh",
    "${path.module}/stdout.${null_resource.start.id}"]
}

data "external" "stderr" {
  depends_on = [
    null_resource.shell]
  program = [
    "sh",
    "${path.module}/read.sh",
    "${path.module}/stderr.${null_resource.start.id}"]
}

data "external" "exitstatus" {
  depends_on = [
    null_resource.shell]
  program = [
    "sh",
    "${path.module}/read.sh",
    "${path.module}/exitstatus.${null_resource.start.id}"]
}

resource "null_resource" "contents" {
  depends_on = [
    null_resource.shell]

  triggers = {
    stdout = data.external.stdout.result["content"]
    stderr = data.external.stderr.result["content"]
    exitstatus = data.external.exitstatus.result["content"]
    string = var.trigger
  }

  lifecycle {
    ignore_changes = [
      triggers]
  }
}