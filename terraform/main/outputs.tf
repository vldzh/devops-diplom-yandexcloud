output "network_id" {
  description = "ID of the VPC network"
  value       = yandex_vpc_network.k8s_network.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = yandex_vpc_network.k8s_network.name
}

output "subnet_a_id" {
  description = "ID of subnet in zone a"
  value       = yandex_vpc_subnet.k8s_subnet_a.id
}

output "subnet_b_id" {
  description = "ID of subnet in zone b"
  value       = yandex_vpc_subnet.k8s_subnet_b.id
}

output "subnet_d_id" {
  description = "ID of subnet in zone d"
  value       = yandex_vpc_subnet.k8s_subnet_d.id
}

output "subnets_map" {
  description = "Map of all subnets with zones as keys"
  value = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_subnet_a.id
    "ru-central1-b" = yandex_vpc_subnet.k8s_subnet_b.id
    "ru-central1-d" = yandex_vpc_subnet.k8s_subnet_d.id
  }
}

output "subnet_cidrs" {
  description = "CIDR blocks of all subnets"
  value = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_subnet_a.v4_cidr_blocks
    "ru-central1-b" = yandex_vpc_subnet.k8s_subnet_b.v4_cidr_blocks
    "ru-central1-d" = yandex_vpc_subnet.k8s_subnet_d.v4_cidr_blocks
  }
}


output "subnet_ids" {
  value = {
    a = yandex_vpc_subnet.k8s_subnet_a.id
    b = yandex_vpc_subnet.k8s_subnet_b.id
    d = yandex_vpc_subnet.k8s_subnet_d.id
  }
}

output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s_cluster.id
}

output "k8s_cluster_name" {
  value = yandex_kubernetes_cluster.k8s_cluster.name
}

output "k8s_cluster_external_v4_endpoint" {
  value = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
}
