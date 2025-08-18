resource "yandex_iam_service_account" "terraform_sa" {
  name        = var.sa_name
  description = "Service account for Terraform operations"
}

# Назначение ролей сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_sauser" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}