
output "web_public_ip" {
  description = "Публичный IP-адрес ВМ web"
  value       = yandex_compute_instance.web.network_interface[0].nat_ip_address
}

output "web_private_ip" {
  description = "Внутренний IP-адрес ВМ web"
  value       = yandex_compute_instance.web.network_interface[0].ip_address
}

output "worker_private_ip" {
  description = "Внутренний IP-адрес ВМ worker (публичного IP нет)"
  value       = yandex_compute_instance.worker.network_interface[0].ip_address
}

output "vpc_id" {
  description = "ID VPC"
  value       = yandex_vpc_network.main.id
}

output "subnet_id" {
  description = "ID подсети"
  value       = yandex_vpc_subnet.main.id
}

output "web_instance_id" {
  description = "ID ВМ web"
  value       = yandex_compute_instance.web.id
}

output "worker_instance_id" {
  description = "ID ВМ worker"
  value       = yandex_compute_instance.worker.id
}
