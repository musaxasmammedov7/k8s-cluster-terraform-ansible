output "controller_public_ip" {
  description = "Public IP address of Kubernetes controller node"
  value       = aws_instance.controller.public_ip
}

output "controller_private_ip" {
  description = "Private IP address of Kubernetes controller node"
  value       = aws_instance.controller.private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of Kubernetes worker nodes"
  value       = aws_instance.workers[*].public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of Kubernetes worker nodes"
  value       = aws_instance.workers[*].private_ip
}

output "ansible_inventory" {
  description = "Ready-to-use Ansible inventory content"
  value       = <<-EOT
[controllers]
controller-0 ansible_host=${aws_instance.controller.public_ip} ansible_user=ubuntu internal_ip=${aws_instance.controller.private_ip}

[workers]
%{for idx, inst in aws_instance.workers~}
worker-${idx} ansible_host=${inst.public_ip} ansible_user=ubuntu internal_ip=${inst.private_ip} pod_cidr=10.200.${idx}.0/24
%{endfor~}

[k8s_cluster:children]
controllers
workers
EOT
}
