# Создание бакета для Terraform state
resource "yandex_storage_bucket" "terraform_state" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  versioning {
    enabled = true
  }

}

output "bucket_id" {
  value = yandex_storage_bucket.terraform_state.id
}
