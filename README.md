# Лабораторная работа 4 — Terraform и Yandex Cloud (Windows, без Docker)

Проект создаёт в Yandex Cloud VPC, подсеть `10.10.0.0/24`, две виртуальные машины Ubuntu 22.04 LTS и две группы безопасности. `web` получает публичный IP и запускает nginx в Docker на порту 8080. `worker` не получает публичный IP и записывает отметку времени в `/var/log/worker.log` каждую минуту.

> Виртуальные машины могут тарифицироваться. После проверки обязательно выполните `terraform destroy`.

## Содержимое

- `main.tf` — сеть, подсеть, группы безопасности и две ВМ.
- `variables.tf` — параметры конфигурации.
- `outputs.tf` — публичный и внутренние IP, идентификаторы ресурсов.
- `versions.tf` — версия Terraform и провайдер Yandex Cloud.
- `.gitignore` — исключения для локальных секретов и Terraform state.

## 1. Установите инструменты

Установите Terraform для Windows (AMD64) из зеркала Yandex:

`https://mirror.yandex.ru/mirrors/releases.hashicorp.com/terraform/`

Скачайте ZIP нужной версии, распакуйте `terraform.exe`, например в `C:\Terraform`, и добавьте `C:\Terraform` в пользовательскую переменную `Path`. Откройте новое окно PowerShell и проверьте:

```powershell
terraform version
```

Установите Yandex Cloud CLI по официальной инструкции: `https://yandex.cloud/ru/docs/cli/quickstart`, затем авторизуйтесь:

```powershell
yc init
yc version
yc config get cloud-id
yc config get folder-id
```

Для GitHub также нужен Git for Windows: `https://git-scm.com/download/win`.

## 2. (Необязательно) Настройте зеркало провайдера Yandex

Если провайдер не скачивается из Registry напрямую, создайте файл пользовательской настройки Terraform:

```powershell
notepad "$env:APPDATA\terraform.rc"
```

Вставьте и сохраните:

```hcl
provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

Это настройка на компьютере, добавлять её в репозиторий не требуется.

## 3. Перейдите в каталог проекта и настройте авторизацию

Откройте PowerShell в папке, куда распакован проект. Например:

```powershell
cd C:\Users\<ВАШ_ПОЛЬЗОВАТЕЛЬ>\Desktop\DevOps\MLOps_lab4
```

Передайте Terraform временный IAM-токен, cloud ID и folder ID через переменные окружения. Команды не записывают токен в `.tf`-файлы:

```powershell
$Env:YC_TOKEN = yc iam create-token
$Env:YC_CLOUD_ID = yc config get cloud-id
$Env:YC_FOLDER_ID = yc config get folder-id
```

Проверьте, что переменные не пустые, не выводя значение токена:

```powershell
if ($Env:YC_TOKEN) { 'YC_TOKEN задан' }
if ($Env:YC_CLOUD_ID) { 'YC_CLOUD_ID задан' }
if ($Env:YC_FOLDER_ID) { 'YC_FOLDER_ID задан' }
```

IAM-токен временный (не более 12 часов). Если появится ошибка авторизации, получите его заново.

## 4. Создайте SSH-ключ

Если у вас уже есть пара ключей `id_ed25519` и `id_ed25519.pub`, можете использовать её. Иначе выполните:

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
ssh-keygen -t ed25519 -f "$HOME\.ssh\id_ed25519"
```

При запросе passphrase для простоты учебной работы нажмите Enter два раза, либо задайте парольную фразу и используйте её при SSH-подключении. Затем передайте публичный ключ Terraform:

```powershell
$Env:TF_VAR_ssh_public_key = (Get-Content "$HOME\.ssh\id_ed25519.pub" -Raw).Trim()
```

Публичный ключ передаётся в cloud-init; приватный ключ никому не отправляйте.

## 5. Инициализируйте и проверьте конфигурацию

Из корня проекта выполните:

```powershell
terraform init
terraform fmt -recursive
terraform validate
```

Ожидаемый результат проверки: `Success! The configuration is valid.` Если возникла ошибка, исправьте её до создания ресурсов.

## 6. Посмотрите план и создайте ресурсы

Сначала обязательно сформируйте план:

```powershell
terraform plan -out=tfplan
```

Убедитесь, что создаются VPC, подсеть, две группы безопасности и две ВМ. Затем примените именно сохранённый план:

```powershell
terraform apply tfplan
```

Получите IP-адреса:

```powershell
terraform output
terraform output -raw web_public_ip
terraform output -raw web_private_ip
terraform output -raw worker_private_ip
```

`web` должен иметь публичный IP, `worker` — только внутренний.

## 7. Проверьте сервисы

Откройте в браузере `http://<WEB_PUBLIC_IP>:8080`, заменив адрес на значение `web_public_ip`. Должна открыться стандартная страница nginx. Первый запуск может занять несколько минут.

Подключитесь к `web` из PowerShell:

```powershell
ssh -i "$HOME\.ssh\id_ed25519" ubuntu@<WEB_PUBLIC_IP>
```

Подключитесь к `worker` через `web` (SSH jump-host):

```powershell
ssh -i "$HOME\.ssh\id_ed25519" -J ubuntu@<WEB_PUBLIC_IP> ubuntu@<WORKER_PRIVATE_IP>
```

На `worker` проверьте фоновый процесс:

```bash
sudo systemctl status worker.service
sudo tail -n 20 /var/log/worker.log
```

В журнале должны появляться новые строки примерно раз в минуту.

## 8. Повторный plan и удаление ресурсов

После успешного `apply` выполните:

```powershell
terraform plan
```

Ожидается `No changes. Your infrastructure matches the configuration.` Сохраните вывод для отчёта.

После проверки выполните удаление:

```powershell
terraform destroy
```

Подтвердите `yes`. Затем проверьте список ВМ в выбранном каталоге:

```powershell
yc compute instance list
```

Если в каталоге есть другие ВМ, список не будет пустым; убедитесь, что удалены именно `web` и `worker`.

## 9. Публикация на GitHub

Создайте пустой репозиторий на `https://github.com/new`, затем из каталога проекта выполните команды (подставьте свой URL):

```powershell
git init
git add .
git status --short
git commit -m "Complete Terraform lab 4"
git branch -M main
git remote add origin https://github.com/<ВАШ_ЛОГИН>/terraform-yandex-lab.git
git push -u origin main
```

Перед отправкой убедитесь, что не добавляются `terraform.tfstate`, `tfplan`, `.terraform/`, `.ssh/` или файлы `*.tfvars`. Они исключены через `.gitignore`. После `terraform init` рекомендуется сохранить `.terraform.lock.hcl` в Git, поэтому при необходимости уберите эту строку из `.gitignore`, выполните `git add .terraform.lock.hcl` и отправьте коммит.

## Что приложить к отчёту

Сохраните выводы команд `terraform plan`, `terraform apply`, повторного `terraform plan` (`No changes`), `terraform destroy` (`Destroy complete! Resources: N destroyed.`) и `yc compute instance list` после удаления.
