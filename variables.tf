variable "zone" {
  description = "Зона доступности Yandex Cloud"
  type        = string
  default     = "ru-central1-a"
}

variable "network_name" {
  description = "Имя облачной сети VPC"
  type        = string
  default     = "tf-lesson-vpc"
}

variable "subnet_name" {
  description = "Имя подсети"
  type        = string
  default     = "tf-lesson-subnet"
}

variable "subnet_cidr" {
  description = "CIDR подсети"
  type        = string
  default     = "10.10.0.0/24"
}

variable "image_family" {
  description = "Семейство образа Ubuntu LTS"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "platform_id" {
  description = "Платформа виртуальных машин"
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "Количество vCPU на каждой ВМ"
  type        = number
  default     = 2
}

variable "vm_memory_gb" {
  description = "Объём RAM каждой ВМ в ГБ"
  type        = number
  default     = 2
}

variable "boot_disk_size_gb" {
  description = "Размер загрузочного диска в ГБ"
  type        = number
  default     = 10
}

variable "web_instance_name" {
  description = "Имя публичной ВМ"
  type        = string
  default     = "web"
}

variable "worker_instance_name" {
  description = "Имя приватной ВМ"
  type        = string
  default     = "worker"
}

variable "web_security_group_name" {
  description = "Имя группы безопасности web"
  type        = string
  default     = "tf-lesson-web-sg"
}

variable "worker_security_group_name" {
  description = "Имя группы безопасности worker"
  type        = string
  default     = "tf-lesson-worker-sg"
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа для подключения к ВМ"
  type        = string
  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "Передайте публичный SSH-ключ через переменную TF_VAR_ssh_public_key."
  }
}

variable "ssh_port" {
  description = "Порт SSH"
  type        = number
  default     = 22
}

variable "web_api_port" {
  description = "Порт web-сервиса"
  type        = number
  default     = 8080
}

variable "web_ssh_cidr" {
  description = "Откуда разрешён SSH к web (по условию лабораторной — весь интернет)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_api_cidr" {
  description = "Откуда разрешён доступ к API web"
  type        = string
  default     = "0.0.0.0/0"
}
