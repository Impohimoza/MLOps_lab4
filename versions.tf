terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0, < 1.0.0"
    }
  }
}

provider "yandex" {
  zone = var.zone
  # YC_TOKEN, YC_CLOUD_ID и YC_FOLDER_ID берутся из переменных окружения.
}
