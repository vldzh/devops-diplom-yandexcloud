resource "yandex_container_registry" "diploma_registry" {
  name      = "diploma-registry"
  folder_id = var.folder_id
}

output "registry_id" {
  value = yandex_container_registry.diploma_registry.id
}
