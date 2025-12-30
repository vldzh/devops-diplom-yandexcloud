resource "yandex_vpc_network" "k8s_network" {
  name        = "k8s-network"
  description = "Network for Kubernetes cluster"
  labels = {
    environment = "diploma"
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_subnet" "k8s_subnet_a" {
  name           = "k8s-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  labels = {
    environment = "diploma"
    zone        = "a"
  }
}

resource "yandex_vpc_subnet" "k8s_subnet_b" {
  name           = "k8s-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  labels = {
    environment = "diploma"
    zone        = "b"
  }
}

resource "yandex_vpc_subnet" "k8s_subnet_d" {
  name           = "k8s-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  labels = {
    environment = "diploma"
    zone        = "d"
  }
}
