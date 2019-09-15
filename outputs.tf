output "private_ip" {
  value = aws_spot_instance_request.this.private_ip
}

output "instance_id" {
  value = chomp(null_resource.contents.triggers["stdout"])
}

output "stdout" {
  value = chomp(null_resource.contents.triggers["stdout"])
  #value = "${data.external.stdout.result["content"]}"
}

output "stderr" {
  value = chomp(null_resource.contents.triggers["stderr"])
  #value = "${data.external.stderr.result["content"]}"
}

output "exitstatus" {
  value = chomp(null_resource.contents.triggers["exitstatus"])
  #value = "${data.external.exitstatus.result["content"]}"
}

//output "ami_id" {
//  value = data.aws_ami.ubuntu.id
//}
//
//output "user_data" {
//  value = data.template_file.user_data.rendered
//}
