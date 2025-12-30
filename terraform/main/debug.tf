output "debug_vars" {
  value = {
    token_length   = length(var.yc_token)
    token_first_10 = substr(var.yc_token, 0, 10)
    cloud_id       = var.cloud_id
    folder_id      = var.folder_id
    zone           = var.default_zone
  }
  sensitive = true # To avoid exposing full token
}


