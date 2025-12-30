variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = false
}

variable "sa_id" {
  description = "Service Account ID"
  type        = string
  sensitive   = false
}

variable "yc_token" {
  description = "IAM Token for Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = false
}

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "sa_name" {
  type    = string
  default = "terraform-sa"
}

variable "bucket_name" {
  type    = string
  default = "netology-diploma-vladyezh-tfstate"
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}
