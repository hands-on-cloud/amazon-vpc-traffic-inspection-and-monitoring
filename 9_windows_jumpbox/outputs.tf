output "public_ip" {
  value = aws_instance.ec2_windows_jumpbox.public_ip
  description = "Windows Jumpbox public IP address for RDP connections"
}
