output "suricata_interface_id" {
  value = aws_network_interface.suricata.id
  description = "Suricata EC instance network interface ID"
}
