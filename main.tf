
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_vpc_network" "main" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "main" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_cidr]
}

resource "yandex_vpc_security_group" "web" {
  name        = var.web_security_group_name
  network_id  = yandex_vpc_network.main.id
  description = "Доступ к web по SSH и TCP/8080"

  ingress {
    protocol       = "TCP"
    description    = "SSH к web"
    v4_cidr_blocks = [var.web_ssh_cidr]
    port           = var.ssh_port
  }

  ingress {
    protocol       = "TCP"
    description    = "Веб-сервис на порту 8080"
    v4_cidr_blocks = [var.web_api_cidr]
    port           = var.web_api_port
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик для установки Docker и nginx"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "worker" {
  name        = var.worker_security_group_name
  network_id  = yandex_vpc_network.main.id
  description = "SSH к worker только из внутренней подсети"

  ingress {
    protocol       = "TCP"
    description    = "SSH из внутренней сети"
    v4_cidr_blocks = [var.subnet_cidr]
    port           = var.ssh_port
  }
}

resource "yandex_compute_instance" "web" {
  name        = var.web_instance_name
  hostname    = var.web_instance_name
  zone        = var.zone
  platform_id = var.platform_id

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory_gb
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size_gb
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    "user-data" = <<-CLOUD_INIT
      #cloud-config
      datasource:
        Ec2:
          strict_id: false
      ssh_pwauth: no
      users:
        - name: ubuntu
          groups: [sudo]
          shell: /bin/bash
          sudo: 'ALL=(ALL) NOPASSWD:ALL'
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      package_update: true
      packages:
        - docker.io
      runcmd:
        - [sh, -c, "systemctl enable --now docker"]
        - [sh, -c, "docker run -d --restart unless-stopped --name nginx -p 8080:80 nginx:latest"]
      CLOUD_INIT
  }

  allow_stopping_for_update = true
}

resource "yandex_compute_instance" "worker" {
  name        = var.worker_instance_name
  hostname    = var.worker_instance_name
  zone        = var.zone
  platform_id = var.platform_id

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory_gb
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.boot_disk_size_gb
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.worker.id]
  }

  metadata = {
    "user-data" = <<-CLOUD_INIT
      #cloud-config
      datasource:
        Ec2:
          strict_id: false
      ssh_pwauth: no
      users:
        - name: ubuntu
          groups: [sudo]
          shell: /bin/bash
          sudo: 'ALL=(ALL) NOPASSWD:ALL'
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      packages:
        - python3
      write_files:
        - path: /usr/local/bin/worker.sh
          owner: root:root
          permissions: '0755'
          content: |
            #!/bin/bash
            while true; do
              echo "Task $(date)" >> /var/log/worker.log
              sleep 60
            done
        - path: /etc/systemd/system/worker.service
          owner: root:root
          permissions: '0644'
          content: |
            [Unit]
            Description=Background worker for Terraform lab
            After=network.target

            [Service]
            Type=simple
            ExecStart=/usr/local/bin/worker.sh
            Restart=always

            [Install]
            WantedBy=multi-user.target
      runcmd:
        - [systemctl, daemon-reload]
        - [systemctl, enable, --now, worker.service]
      CLOUD_INIT
  }

  allow_stopping_for_update = true
}
