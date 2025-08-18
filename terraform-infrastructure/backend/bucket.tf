# Создание статического ключа доступа для S3
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.terraform_sa.id
  description        = "Static access key for Terraform state bucket"
}

# Создание бакета для хранения Terraform state
resource "yandex_storage_bucket" "terraform_state" {
  bucket     = var.bucket_name
  acl        = "private"
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  versioning {
    enabled = true
  }
}