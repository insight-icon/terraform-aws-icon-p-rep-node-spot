output "private_ip" {
  value = aws_spot_instance_request.this.private_ip
}

output "instance_id" {
  value = module.instance_id.stdout
}

//output "ami_id" {
//  value = data.aws_ami.ubuntu.id
//}
//
//output "user_data" {
//  value = data.template_file.user_data.rendered
//}
