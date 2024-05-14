
output "kubernetes_master_ip" {
  value = aws_instance.kubernetes_master.public_ip
}

output "kubernetes_worker1_ip" {
  value = aws_instance.kubernetes_worker1.public_ip
}

output "kubernetes_worker2_ip" {
  value = aws_instance.kubernetes_worker2.public_ip
}
