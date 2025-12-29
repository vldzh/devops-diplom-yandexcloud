# Дипломный практикум в Yandex.Cloud
---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Установим Yandex cloud CLI
```
vlad@DESKTOP-2V70QV1:~/netology$ curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
Downloading yc 0.185.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  158M  100  158M    0     0  15.0M      0  0:00:10  0:00:10 --:--:-- 16.5M
Yandex Cloud CLI 0.185.0 linux/amd64

yc PATH has been added to your '/home/vlad/.bashrc' profile
yc bash completion has been added to your '/home/vlad/.bashrc' profile.
Now we have zsh completion. Type "echo 'source /home/vlad/yandex-cloud/completion.zsh.inc' >>  ~/.zshrc" to install itTo complete installation, start a new shell (exec -l $SHELL) or type 'source "/home/vlad/.bashrc"' in the current one
vlad@DESKTOP-2V70QV1:~/netology$ source "/home/vlad/.bashrc"
```
Инициализируем Yandex cloud CLI:
```
vlad@DESKTOP-2V70QV1:~/netology$ yc init
Welcome! This command will take you through the configuration process.
...
...
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
vlad@DESKTOP-2V70QV1:~/netology$ yc iam service-account create --name terraform-sa

done (2s)
id: axxxxxxxxxxxxxxx2
folder_id: bxxxxxxxxxxxxxxxxx2
created_at: "2025-12-28T10:57:26Z"
name: terraform-sa
```

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создадим сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
```

vlad@DESKTOP-2V70QV1:~/netology$ SA_ID=$(yc iam service-account get terraform-sa --format json | jq -r .id)

# Назначение ролей
vlad@DESKTOP-2V70QV1:~/netology$ yc resource-manager folder add-access-binding bxxxxxxxxxxxxx2 \
>   --role editor \
>   --subject serviceAccount:$SA_ID
done (21s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: editor
      subject:
        id: axxxxxxxxxxxxxxxx2
        type: serviceAccount

# Создание ключа
vlad@DESKTOP-2V70QV1:~/netology$ yc iam key create --service-account-id $SA_ID --output key.json
id: axxxxxxxxxxxxxxxe
service_account_id: axxxxxxxxxxxxxxx2
created_at: "2025-12-28T11:09:33.633843998Z"
key_algorithm: RSA_2048

```

создадим  директорию для terraform инфраструктуры, проверим  глобальную конфигурации Terraform
```
vlad@DESKTOP-2V70QV1:~/netology/devops-diplom-yandexcloud$ mkdir -p terraform/{backend,main,modules}
vlad@DESKTOP-2V70QV1:~/netology/devops-diplom-yandexcloud$ tree -L 2
.
├── README.md
└── terraform
    ├── backend
    ├── main
    └── modules

5 directories, 1 file
vlad@DESKTOP-2V70QV1:~/netology/devops-diplom-yandexcloud$ cat ~/.terraform.d/terraform.rc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
Установим и проверим переменные окуружения
```
vlad@DESKTOP-2V70QV1:~/netology/devops-diplom-yandexcloud$ export TF_VAR_cloud_id=$(yc config get cloud-id)
export TF_VAR_folder_id=$(yc config get folder-id)
export TF_VAR_yc_token=$(yc iam create-token)
export TF_VAR_sa_id=$SA_ID

vlad@DESKTOP-2V70QV1:~/netology/devops-diplom-yandexcloud$ echo "TF_VAR_cloud_id:  $TF_VAR_cloud_id"
echo "TF_VAR_folder_id: $TF_VAR_folder_id"
echo "TF_VAR_sa_id:     $TF_VAR_sa_id"
echo "TF_VAR_yc_token:  $TF_VAR_yc_token"
TF_VAR_cloud_id:  b1gn................
TF_VAR_folder_id: b1g2................
TF_VAR_sa_id:     ajef................
TF_VAR_yc_token:  t1.9..........................................................
```


Создаем корневую директорию проекта
```
mkdir -p ~/devops-diplom-yandexcloud
cd ~/devops-diplom-yandexcloud
```
Создаем структуру для backend
```
mkdir -p terraform/backend
cd terraform/backend
```
Создаем файл variables.tf для backend
```
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ cat variables.tf 
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
```
Создаем файл providers.tf для backend
```
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ cat providers.tf 
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}
```


2. Подготовим  backend для Terraform - S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
```
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ cat main.tf 
# Создание бакета для Terraform state
resource "yandex_storage_bucket" "terraform_state" {
  bucket    = var.bucket_name
  folder_id = var.folder_id
  acl       = "private"

  versioning {
    enabled = true
  }

}

output "bucket_id" {
  value = yandex_storage_bucket.terraform_state.id
}
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ cat providers.tf 
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}
```

3. Создадим конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
```
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ terraform   plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_storage_bucket.terraform_state will be created
  + resource "yandex_storage_bucket" "terraform_state" {
      + acl                   = "private"
      + bucket                = "netology-diploma-vladyezh-tfstate"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = "b...............s2"
      + force_destroy         = false
      + id                    = (known after apply)
      + policy                = (known after apply)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags (known after apply)

      + grant (known after apply)

      + versioning {
          + enabled = true
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_id   = (known after apply)
  - bucket_name = "netology-diploma-tfstate-$(substr(md5(var.folder_id), 0, 8))" -> null
╷
│ Warning: Argument is deprecated
│ 
│   with yandex_storage_bucket.terraform_state,
│   on main.tf line 5, in resource "yandex_storage_bucket" "terraform_state":
│    5:   acl       = "private"
│ 
│ Use `yandex_storage_bucket_grant` instead.
╵

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
vlad@DESKTOP-2V70QV1:~/devops-diplom-yandexcloud/terraform/backend$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_storage_bucket.terraform_state will be created
  + resource "yandex_storage_bucket" "terraform_state" {
      + acl                   = "private"
      + bucket                = "netology-diploma-vladyezh-tfstate"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = "b..............2"
      + force_destroy         = false
      + id                    = (known after apply)
      + policy                = (known after apply)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags (known after apply)

      + grant (known after apply)

      + versioning {
          + enabled = true
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_id   = (known after apply)
  - bucket_name = "netology-diploma-tfstate-$(substr(md5(var.folder_id), 0, 8))" -> null
╷
│ Warning: Argument is deprecated
│ 
│   with yandex_storage_bucket.terraform_state,
│   on main.tf line 5, in resource "yandex_storage_bucket" "terraform_state":
│    5:   acl       = "private"
│ 
│ Use `yandex_storage_bucket_grant` instead.
│ 
│ (and one more similar warning elsewhere)
╵

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_storage_bucket.terraform_state: Creating...
yandex_storage_bucket.terraform_state: Still creating... [00m10s elapsed]
yandex_storage_bucket.terraform_state: Creation complete after 14s [id=netology-diploma-vladyezh-tfstate]
╷
│ Warning: Argument is deprecated
│ 
│   with yandex_storage_bucket.terraform_state,
│   on main.tf line 5, in resource "yandex_storage_bucket" "terraform_state":
│    5:   acl       = "private"
│ 
│ Use `yandex_storage_bucket_grant` instead.
╵

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_id = "netology-diploma-vladyezh-tfstate"
```

4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform
---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

