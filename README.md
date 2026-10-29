# Лабораторная работа 4 — Terraform и Yandex Cloud

Проект создаёт в Yandex Cloud VPC, подсеть `10.10.0.0/24`, две виртуальные машины Ubuntu 22.04 LTS и две группы безопасности. `web` получает публичный IP и запускает nginx в Docker на порту 8080. `worker` не получает публичный IP и записывает отметку времени в `/var/log/worker.log` каждую минуту.

## Авторы
Бекевич Иван Михайлович - (Himozaa)
Березин Роман Вячеславович - (Shankly8642)

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

## 2. Перейдите в каталог проекта и настройте авторизацию

Откройте PowerShell в папке, куда распакован проект
Передайте Terraform временный IAM-токен, cloud ID и folder ID через переменные окружения. Команды не записывают токен в `.tf`-файлы:

```powershell
$Env:YC_TOKEN = yc iam create-token
$Env:YC_CLOUD_ID = yc config get cloud-id
$Env:YC_FOLDER_ID = yc config get folder-id
```

IAM-токен временный (не более 12 часов). Если появится ошибка авторизации, получите его заново.

## 3. Создайте SSH-ключ

Если у вас уже есть пара ключей `id_ed25519` и `id_ed25519.pub`, можете использовать её. Иначе выполните:

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
ssh-keygen -t ed25519 -f "$HOME\.ssh\id_ed25519"
```

```powershell
$Env:TF_VAR_ssh_public_key = (Get-Content "$HOME\.ssh\id_ed25519.pub" -Raw).Trim()
```

Публичный ключ передаётся в cloud-init; приватный ключ никому не отправляйте.

## 4. Инициализируйте и проверьте конфигурацию

Из корня проекта выполните:

```powershell
terraform init
terraform fmt -recursive
terraform validate
```

Ожидаемый результат проверки: `Success! The configuration is valid.` Если возникла ошибка, исправьте её до создания ресурсов.

## 5. Посмотрите план и создайте ресурсы

Сначала сформируйте план:

```powershell
terraform plan
```

Убедитесь, что создаются VPC, подсеть, две группы безопасности и две ВМ. Затем примените план:

```powershell
terraform apply
```

## 6. Проверьте сервисы

Откройте в браузере `http://<WEB_PUBLIC_IP>:8080`, заменив адрес на значение `web_public_ip`. Должна открыться стандартная страница nginx. Первый запуск может занять несколько минут.

## 7. Повторный plan и удаление ресурсов

После успешного `apply` выполните:

```powershell
terraform plan
```

Ожидается `No changes. Your infrastructure matches the configuration.`
После проверки выполните удаление:

```powershell
terraform destroy
```

Подтвердите `yes`. Затем проверьте список ВМ в выбранном каталоге:

```powershell
yc compute instance list
```

Если в каталоге есть другие ВМ, список не будет пустым; убедитесь, что удалены именно `web` и `worker`.