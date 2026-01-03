resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name        = "diploma-k8s-cluster"
  description = "Kubernetes cluster for diploma project"
  network_id  = yandex_vpc_network.k8s_network.id

  master {
    regional {
      region = "ru-central1"
      location {
        zone      = "ru-central1-a"
        subnet_id = yandex_vpc_subnet.k8s_subnet_a.id
      }
      location {
        zone      = "ru-central1-b"
        subnet_id = yandex_vpc_subnet.k8s_subnet_b.id
      }
      location {
        zone      = "ru-central1-d"
        subnet_id = yandex_vpc_subnet.k8s_subnet_d.id
      }
    }

    version   = "1.32"
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "03:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = var.sa_id
  node_service_account_id = var.sa_id

  depends_on = [
    yandex_vpc_subnet.k8s_subnet_a,
    yandex_vpc_subnet.k8s_subnet_b,
    yandex_vpc_subnet.k8s_subnet_d
  ]
}

resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "diploma-node-group"

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat = true
      subnet_ids = [
        yandex_vpc_subnet.k8s_subnet_a.id,
        yandex_vpc_subnet.k8s_subnet_b.id,
        yandex_vpc_subnet.k8s_subnet_d.id
      ]
    }

    resources {
      memory        = 4
      cores         = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    scheduling_policy {
      preemptible = true
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      start_time = "02:00"
      duration   = "3h"
    }
  }
}
