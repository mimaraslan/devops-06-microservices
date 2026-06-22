# Java Microservices Project ve DevOps

Yüksek eşzamanlılık ve dağıtık dayanıklılık hedefleriyle tasarlanmış, **Spring Boot 3** ve **Spring Cloud** tabanlı bir **para transferi ve hesap yönetimi** mikroservis sistemidir. İstemci trafiği API Gateway üzerinden yönlendirilir; iş kuralları domain servislerine ayrılmıştır; **Kafka** ile asenkron entegrasyon, **Redis** ile önbellek ve hız sınırı, **PostgreSQL** ile kalıcılık, **Keycloak** ile kimlik doğrulama kullanılır.

> **Ek dokümantasyon:** Derinlemesine akışlar, Docker adımları, case study karşılaştırması ve mimari notlar için [`README/`](README/) klasöründeki Markdown raporlarına bakın (aşağıda indekslenmiştir).

---

## İçindekiler

- [Özellikler](#özellikler)
- [Teknoloji yığını](#teknoloji-yığını)
- [Modül yapısı](#modül-yapısı)
- [Mimari genel bakış](#mimari-genel-bakış)
- [Docker Compose başlatma sırası](#docker-compose-başlatma-sırası)
- [Para transferi akışı (özet)](#para-transferi-akışı-özet)
- [Hızlı başlangıç](#hızlı-başlangıç)
- [Portlar ve adresler](#portlar-ve-adresler)
- [Yapılandırma](#yapılandırma)
- [AWS EKS + ECR deployment](#aws-eks--ecr-deployment)
- [EKS duraklatma ve devam](#eks-duraklatma-ve-devam)
- [README rapor indeksi](#readme-rapor-indeksi)

---

## Özellikler

| Alan | Açıklama |
|------|-----------|
| **Hesap yönetimi** | Kayıt, giriş, profil; hesap listesi ve detay. Redis ile hesap okuma önbelleği. |
| **Defter (ledger)** | IBAN bazlı bakiye; transfer başlatma, fraud sonrası atomik bakiye güncellemesi. |
| **Idempotency** | `transferId` ile tekrarlayan isteklerde çift işlem engeli (`TransferInitService`). |
| **Eşzamanlı transfer** | Optimistic locking ve sürüm kontrollü SQL güncellemeleri (`TransferProcessService`, `LedgerRepository`). |
| **Fraud** | Kafka üzerinden asenkron fraud kontrolü; Resilience4j circuit breaker. |
| **Bildirim** | Transfer tamamlanınca Kafka ile tetiklenen bildirim servisi. |
| **API Gateway** | Spring Cloud Gateway, Eureka tabanlı `lb://` yönlendirme, circuit breaker fallback’leri, isteğe bağlı Redis rate limit. |
| **Gözlemlenebilirlik** | Zipkin / Micrometer tracing (yapılandırma servislere göre); Actuator health. |
| **Merkezi hata modeli** | Paylaşılan exception tipleri ve HTTP eşlemesi (`GlobalExceptionHandlerLib`). |

Case study ve iyileştirme özetleri için bkz. [`README/CASE_STUDY_EVALUATION_UPDATED.md`](README/CASE_STUDY_EVALUATION_UPDATED.md).

---

## Teknoloji yığını

- **Java 21**, **Gradle** (çok modüllü proje)
- **Spring Boot 3.0.x**, **Spring Cloud 4.0.x** (kök `build.gradle` içinde `versions` / `libs` ile sabitlenmiş sürümler)
- **Spring Cloud Netflix Eureka** — servis keşfi
- **Spring Cloud Config** — yerel `native` profil ile `classpath:/config-repo` üzerinden ortak YAML
- **Spring Cloud Gateway** (WebFlux), **OAuth2 Resource Server** (JWT / Keycloak JWK)
- **Kafka (Redpanda)** — asenkron mesajlaşma (Kafka API uyumlu; altyapıda Redpanda broker)
- **PostgreSQL**, **Redis**
- **Keycloak** — kullanıcı yönetimi ve token (Account servisi entegrasyonu)
- **Resilience4j**, **Spring Retry** (seçili dış çağrılarda)
- **OpenAPI / Springdoc** — API dokümantasyonu (Gateway üzerinden toplanan URL’ler)

---

## Modül yapısı

| Modül | Rol |
|--------|-----|
| `ConfigServerLocal` | Merkezi yapılandırma sunucusu (`8888`). |
| `DashboardEurekaServer` | Eureka + Spring Boot Admin odaklı keşif paneli (`8761`). |
| `ApiGatewayService` | Tek giriş noktası; güvenlik ve route filtreleri (`80` veya `SERVER_PORT`). |
| `AccountService` | Kullanıcı / hesap API’leri, Keycloak, Redis cache. |
| `LedgerService` | Transfer başlatma, Kafka producer/consumer, optimistic locking ile bakiye. |
| `FraudService` | Fraud Kafka consumer, circuit breaker. |
| `NotificationService` | Tamamlanan transferler için bildirim tüketicisi. |
| `GlobalExceptionHandlerLib` | Ortak exception sınıfları (JAR olarak diğer servislere bağımlılık). |

Modül listesi `settings.gradle` dosyasında tanımlıdır.

---

## Mimari genel bakış

```
                         ┌─────────────────────────────────────────────────────────────┐
                         │                    DOMAIN SERVISLERI                        │
  ┌──────────┐           │  ┌─────────┐ ┌────────┐ ┌───────┐ ┌────────────────┐        │
  │  Istemci │──HTTP──▶  │  │ Account │ │ Ledger │ │ Fraud │ │ Notification   │        │
  │ Web/API  │           │  └────┬────┘ └────┬───┘ └───┬───┘ └───────┬────────┘        │
  └──────────┘           │       │           │         │             │                 │
       │                 └───────┼───────────┼─────────┼─────────────┼─────────────────┘
       │                         │           │         │             │
       ▼                         ▼           ▼         ▼             ▼
  ┌─────────────┐         ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐
  │ API Gateway │────────▶│ Keycloak │ │PostgreSQL│ │  Redis  │ │  Kafka   │
  │   :80       │         └──────────┘ │    DB    │ │  cache  │ │  :9092   │
  └──────┬──────┘                      └──────────┘ └─────────┘ └──────────┘
         │
         ▼
  ┌──────────────────────┐
  │ Eureka + Config      │
  │ :8761        :8888   │
  └──────────────────────┘
```

---

## Docker Compose başlatma sırası

`docker compose up -d` tek komutla tüm yığını başlatır. Compose, `depends_on` ve **healthcheck** ile servisleri dalgalar halinde ayağa kaldırır; böylece mikroservisler veritabanı / Kafka / Keycloak hazır olmadan açılmaz, API Gateway de backend’ler **healthy** olduktan sonra başlar.

### Dalga diyagramı

```
  DALGA 1 (paralel)          DALGA 2 (paralel)              DALGA 3
 ┌─────────────────┐       ┌──────────────────────┐       ┌───────────────┐
 │ postgres        │       │ postgres-init        │       │ config-server │
 │ redis           │  ──▶  │ keycloak             │  ──▶  └───────┬───────┘
 │ kafka           │       │ eureka-server        │               │
 │ zipkin          │       └──────────────────────┘               │
 └─────────────────┘                                              ▼
                                                         DALGA 4 (paralel)
                                              ┌──────────────────────────────┐
                                              │ account-service              │
                                              │ ledger-service               │
                                              │ fraud-service                │
                                              │ notification-service         │
                                              └──────────────┬───────────────┘
                                                             │
                                                             ▼
                                                    DALGA 5
                                              ┌──────────────────┐
                                              │   api-gateway    │
                                              │       :80        │
                                              └──────────────────┘
```

> **Not:** Dalga 4'teki mikroservisler `eureka-server` ve `config-server` healthy olduktan sonra başlar; `zipkin` için yalnızca `service_started` beklenir (healthcheck zorunlu değil).

### Detaylı bağımlılıklar

```
                              ┌─────────────────┐
                              │   api-gateway   │
                              └────────┬────────┘
           ┌────────────┬───────────┼───────────┬────────────┐
           ▼            ▼           ▼           ▼            ▼
    ┌────────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐
    │  account   │ │  ledger  │ │  fraud  │ │ notify  │ keycloak     │
    │  service   │ │  service │ │ service │ │ service │ redis        │
    └─────┬──────┘ └────┬─────┘ └────┬────┘ └────┬────┘ │ config     │
          │             │            │           │      │ eureka     │
          │             │            │           │      └────────────┘
          ▼             ▼            ▼           ▼
    ┌─────────────────────────────────────────────────────────────┐
    │  postgres ◀── postgres-init    kafka       zipkin (started) │
    └─────────────────────────────────────────────────────────────┘
```

| Kaynak | Bağımlı servisler |
|--------|-------------------|
| `postgres` | `postgres-init`, `keycloak`, `account`, `ledger` |
| `postgres-init` | `account`, `ledger` (completed) |
| `redis` | `account`, `ledger`, `api-gateway` |
| `kafka` | `ledger`, `fraud`, `notification` |
| `keycloak` | `account`, `api-gateway` |
| `eureka-server` | `config-server`, tüm mikroservisler, `api-gateway` |
| `config-server` | tüm mikroservisler, `api-gateway` |
| `zipkin` | tüm mikroservisler (started) |
| 4 mikroservis | `api-gateway` (healthy) |

### Servis bağımlılıkları (özet)

| Servis | Beklediği koşullar |
|--------|-------------------|
| `postgres-init` | `postgres` **healthy** |
| `keycloak` | `postgres` **healthy** (+ kendi healthcheck, ~1–2 dk) |
| `eureka-server` | Bağımsız (ilk platform servisi) |
| `config-server` | `eureka-server` **healthy** |
| `account-service` | `postgres-init` **completed**, `postgres` + `redis` + `keycloak` **healthy**, `config-server` + `eureka-server` **healthy**, `zipkin` **started** |
| `ledger-service` | `postgres-init` **completed**, `postgres` + `redis` + `redpanda` **healthy**, `config-server` + `eureka-server` **healthy**, `zipkin` **started** |
| `fraud-service` / `notification-service` | `redpanda` **healthy**, `config-server` + `eureka-server` **healthy**, `zipkin` **started** |
| `api-gateway` | Tüm mikroservisler + `keycloak` + `redis` + `config-server` + `eureka-server` **healthy**, `zipkin` **started** |

### Healthcheck notları

| Bileşen | Kontrol |
|---------|---------|
| PostgreSQL | `pg_isready` |
| Redis | `redis-cli ping` |
| Redpanda (Kafka) | `rpk cluster health` |
| Keycloak | `/health/ready` (TCP) |
| Eureka / Config / mikroservisler / Gateway | `curl` → `/actuator/health` |
| Zipkin | `wget` → `/health` |

İlk `docker compose up` sonrası Keycloak ve Spring Boot uygulamalarının tam hazır olması **2–4 dakika** sürebilir. Durum için:

```bash
docker compose ps
docker compose logs -f api-gateway
```

Ayrıntılı Docker adımları ve sorun giderme: [`README/DOCKER_DEPLOYMENT_GUIDE.md`](README/DOCKER_DEPLOYMENT_GUIDE.md).

---

## Para transferi akışı (özet)

1. **Ledger** transfer isteğini doğrular, deftere kayıt açar, **Kafka** üzerinden fraud kuyruğuna yollar.
2. **Fraud** mesajı işler, sonucu sonuç konusuna yazar.
3. **Ledger** sonucu tüketir: başarılıysa **optimistic locking** ile bakiye güncellenir; başarısızlıkta tutarlı geri alma ve anlamlı HTTP hataları (`InsufficientBalanceException`, `OptimisticLockException`, vb.).
4. **Notification** tamamlanan transfer olayını işler.

Konu adları ve basit sıra diyagramı: [`README/KAFKA_REDIS_AKIS_BASIT.md`](README/KAFKA_REDIS_AKIS_BASIT.md). Daha ayrıntılı Kafka/Redis raporu: [`README/KAFKA_REDIS_USAGE_REPORT.md`](README/KAFKA_REDIS_USAGE_REPORT.md).

---

## Hızlı başlangıç

### Gereksinimler

- **JDK 21**
- **Docker** ve **Docker Compose** (tam yığın için)
- İsteğe bağlı: yerel **PostgreSQL**, **Redis**, **Kafka**, **Keycloak** (Docker kullanmadan çalıştıracaksanız ilgili `application.yml` / ortam değişkenlerini proje yorumlarına göre ayarlayın)

### Derleme

```bash
# Windows
.\gradlew.bat clean build -x test

# Linux / macOS
./gradlew clean build -x test
```

### Docker ile tüm stack

Önerilen sıra ve sorun giderme: [`README/DOCKER_DEPLOYMENT_GUIDE.md`](README/DOCKER_DEPLOYMENT_GUIDE.md).

```bash
cp .env.example .env   # sifreleri ve MAIL_* / KEYCLOAK_* duzenleyin
docker compose up -d --build
```

Compose, [başlatma sırasına](#docker-compose-başlatma-sırası) göre servisleri sırayla açar. İlk kurulumda Keycloak ve tüm Spring servislerinin **healthy** olması birkaç dakika sürebilir; `docker compose ps` ile `healthy` durumunu kontrol edin.

### Yerel IDE (kısaltılmış)

1. Altyapıyı (Postgres, Redis, Kafka, Keycloak, Zipkin) Docker veya yerel olarak ayağa kaldırın.
2. **Eureka** → **Config Server** → diğer servisler → **Gateway** sırasıyla başlatın.
3. Gateway varsayılan **80** portunu kullanır; Windows’ta yönetici izni gerekebilir — `SERVER_PORT=9080` gibi bir port ile `ApiGatewayService` çalıştırıp istemci ve Ledger’deki gateway taban URL’lerini buna göre güncellemeniz gerekebilir.

---

## Portlar ve adresler

Docker ve host eşlemelerinin tam tablosu için: [`README/DOCKER_DEPLOYMENT_GUIDE.md`](README/DOCKER_DEPLOYMENT_GUIDE.md#-servis-erişim-portları).

| Bileşen | Tipik host portu |
|---------|------------------|
| API Gateway | 80 |
| Eureka | 8761 |
| Config Server | 8888 |
| Account | 9591 |
| Ledger | 9592 |
| Fraud | 9593 |
| Notification | 9594 |
| Keycloak (host) | 8180 |
| Zipkin | 9411 |
| PostgreSQL (compose host eşlemesi dokümana göre) | 9999 |
| Redis | 6379 |
| Kafka (Redpanda) | 9092 |

---

## Yapılandırma

- **Config Server:** `ConfigServerLocal/src/main/resources/config-repo/*.yml` altında servis başına profiller.
- **Yerel bootstrap:** Birçok serviste `optional:configserver:` ile Config Server yokken bile sınırlı ayakta kalma.
- **Ortam değişkenleri:** Docker Compose içinde Eureka, Redis, Keycloak JWK URI, Kafka bootstrap vb. override edilir; ayrıntılar yine Docker rehberinde.

---

## AWS EKS + ECR deployment

Proje AWS üzerinde **EKS** (Kubernetes), **ECR** (container registry) ve **Terraform** ile çalışacak şekilde yapılandırılmıştır.

### Altyapı bileşenleri

| Bileşen | Konum | Açıklama |
|---------|-------|----------|
| Terraform — S3 state | `_01_terraform/_01_s3-buckets/` | Remote state bucket |
| Terraform — Jenkins EC2 | `_01_terraform/_02_ec2-main/` | CI sunucusu (`mydemo-server`) |
| Terraform — EKS cluster | `_01_terraform/_03_eks-terraform/` | Cluster, node group, EBS CSI, volume/instance tag'leri |
| Terraform — ECR repos | `_01_terraform/_04_ecr-terraform/` | Mikroservis imajları |
| Jenkins pipeline'ları | `_01_terraform/_05_jenkinsfiles/` | Build + push |
| Kubernetes manifestleri | `_01_terraform/_06_kubernetes-files/` | `kubectl apply -k` |
| Deploy script | `_01_terraform/_06_kubernetes-files/deploy-k8s.ps1` | Secrets + kustomize + Eureka restart sırası |

**Cluster adı:** `project-eks` (bölge: `us-east-1`)

### Kurulum sırası (ilk kez)

1. S3 bucket → EC2 (Jenkins) → ECR repos
2. Jenkins ile Docker imajlarını ECR'ye push
3. EKS cluster + node group (`terraform apply` — `_03_eks-terraform`)
4. `aws eks update-kubeconfig --region us-east-1 --name project-eks`
5. Kubernetes secrets ve manifestler:

```powershell
cd _01_terraform\_06_kubernetes-files
cp secrets.example.yaml secrets.yaml   # sifreleri duzenleyin
.\deploy-k8s.ps1
```

### Public erişim URL'leri

LoadBalancer DNS adreslerini almak için:

```powershell
kubectl get svc api-gateway-service dashboard-eureka-server keycloak
```

| Servis | Adres |
|--------|-------|
| API Gateway | `http://<api-gateway-elb>/` |
| Eureka dashboard | `http://<api-gateway-elb>:8761/` (gateway ile aynı ELB, port 8761) |
| Keycloak admin | `http://<keycloak-elb>:8180/admin/master/console/` |

> **Not:** Keycloak EKS içinde çalışır. Jenkins EC2 IP'si (`54.86.213.216:8180`) yalnızca yerel `docker-compose` içindir; EKS Keycloak'a erişmek için Keycloak servisinin ELB DNS'ini kullanın.

Postman örneği: `POST http://<api-gateway-elb>/account/register`

### Kalıcı Postgres (PVC)

Postgres verisi **EBS PVC** (`postgres-data`, 10 GB `gp2`) üzerinde tutulur. Worker node yeniden başlasa bile veritabanı korunur.

| Depolama | Bileşen | Worker restart sonrası |
|----------|---------|------------------------|
| **PVC (EBS)** | Postgres | Veri **korunur** |
| `emptyDir` | Redis, Kafka (Redpanda) | Veri sıfırlanır (dev ortamı için kabul edilebilir) |

İlk PVC kurulumundan sonra yalnızca `postgres-init-job` bir kez çalıştırılmalıdır; sonraki worker restart'larında tekrar gerekmez.

### AWS kaynak isimlendirme (Terraform)

Terraform ile otomatik `Name` tag'leri:

| Kaynak | Tag değeri | Terraform dosyası |
|--------|------------|-------------------|
| Jenkins EC2 | `mydemo-server` | `_02_ec2-main/myhost.tf` |
| Jenkins root disk | `mydemo-jenkins-root` | `_02_ec2-main/myhost.tf` |
| EKS worker EC2 | `mydemo-eks-worker-node` | `_03_eks-terraform/ebs-volume-tags.tf` |
| EKS worker root disk | `project-eks-worker-root` | `_03_eks-terraform/ebs-volume-tags.tf` |
| Postgres EBS disk | `project-eks-postgres-data` | `_03_eks-terraform/ebs-volume-tags.tf` + `postgres-storageclass.yaml` |

Değişkenler: `_03_eks-terraform/variable.tf` (`instance_name`, `worker_root_volume_name`, `postgres_volume_name`).

### Eureka ve Gateway notları

- Eureka **standalone** modda çalışır (`eureka-server-config.yaml`); peer replication kapalıdır.
- API Gateway, Kubernetes profilinde servislere **doğrudan K8s DNS** ile yönlendirilir (`api-gateway-k8s-config.yaml`); Eureka registry boş olsa bile routing çalışır.
- `deploy-k8s.ps1` Eureka'yı yeniden başlatır ve client servisleri sırayla scale eder.

### pgAdmin / Postgres erişimi

Postgres cluster içinde `ClusterIP` olarak çalışır; gateway ELB üzerinden `:5432` ile erişilemez. Yerel erişim:

```powershell
kubectl port-forward svc/postgres 5433:5432
# pgAdmin: host=localhost, port=5433, user=postgres
```

---

## EKS duraklatma ve devam

Maliyet düşürmek için kaynakları güvenli şekilde duraklatma:

### Duraklat (maliyet tasarrufu)

```powershell
# Jenkins EC2 — AWS konsolundan Stop veya:
aws ec2 stop-instances --instance-ids <jenkins-instance-id>

# EKS worker — node group scale (EC2'yi elle Stop ETMEYIN)
aws eks update-nodegroup-config `
  --cluster-name project-eks `
  --nodegroup-name project-eks-node-group `
  --region us-east-1 `
  --scaling-config minSize=0,maxSize=1,desiredSize=0
```

> Postgres PVC (EBS) worker kapalıyken de **silinmez** (~$0.80/ay disk ücreti devam eder).

**Pause/resume — tek postgres diski (2. volume olmasin)**

- Worker node group **tek AZ** (`Public-Subnet-1`); Terraform `main.tf` — pause/resume'da ayni EBS volume tekrar baglanir.
- Tüm K8s manifestleri **`namespace: default`** (`kustomization.yaml`); `kubectl apply -k . -n dev` ile 2. postgres PVC **olusturmayin**.
- Duraklatırken yalnizca `desiredSize=0`; **PVC/postgres-data silmeyin**, `postgres-init-job` calistirmayin.
- `deploy-k8s.ps1` basinda `dev` (ve diger namespace) postgres kopyasi otomatik silinir.
- ArgoCD Application destination namespace: **default** (postgres ayri namespace'e sync etmeyin).
- EC2 Volumes'te iki isim gorurseniz: **In-use** = aktif, **Available** = yetim (Postgres Running + PVC Bound iken silin).

### Devam ettir

```powershell
# Jenkins EC2 Start
aws ec2 start-instances --instance-ids <jenkins-instance-id>

# EKS worker geri getir
aws eks update-nodegroup-config `
  --cluster-name project-eks `
  --nodegroup-name project-eks-node-group `
  --region us-east-1 `
  --scaling-config minSize=1,maxSize=2,desiredSize=1

aws eks update-kubeconfig --region us-east-1 --name project-eks
kubectl get nodes   # Ready olana kadar bekleyin

cd _01_terraform\_06_kubernetes-files
.\deploy-k8s.ps1
```

PVC kullanıldığı için worker restart sonrası `postgres-init-job` **gerekmez**. Pod'lar `CrashLoopBackOff` olursa: `kubectl get pods` ve `kubectl logs <pod>` ile kontrol edin.

Resume sonrası `deploy-k8s.ps1` zorunlu değildir; pod'lar Pending/CrashLoop ise çalıştırın. **postgres-data PVC'yi asla silmeyin.**

---

## README rapor indeksi

| Dosya | İçerik |
|--------|--------|
| [DOCKER_DEPLOYMENT_GUIDE.md](README/DOCKER_DEPLOYMENT_GUIDE.md) | Docker build, compose, portlar, sorun giderme, kontrol listesi |
| [KAFKA_REDIS_AKIS_BASIT.md](README/KAFKA_REDIS_AKIS_BASIT.md) | Kafka konuları, Redis (cache + rate limit) kısa özet |
| [KAFKA_REDIS_USAGE_REPORT.md](README/KAFKA_REDIS_USAGE_REPORT.md) | Kafka ve Redis kullanımının ayrıntılı raporu |
| [OPTIMISTIC_LOCKING_OZET.md](README/OPTIMISTIC_LOCKING_OZET.md) | Ledger’da optimistic locking ve sürüm güncellemeleri |
| [SAGA_PATTERN_ANALYSIS.md](README/SAGA_PATTERN_ANALYSIS.md) | Saga / dağıtık işlem notları ve analiz |
| [CASE_STUDY_EVALUATION.md](README/CASE_STUDY_EVALUATION.md) | Case study karşılaştırması (özet + tarihsel iyileştirme notları) |
| [CASE_STUDY_EVALUATION_UPDATED.md](README/CASE_STUDY_EVALUATION_UPDATED.md) | Güncellenmiş gereksinim matrisi ve kalan işler |

PDF case study metni varsa: `README/Case Study.pdf` (depoda mevcutsa).

---

## Katkı ve lisans

Bu depo eğitim ve referans amaçlı bir mikroservis iskeletidir. 
Kullanımından önce kendinize ait gizli anahtarların ortam değişkenlerini ayarlamalısınız.
---

**Özet:** Proje, finansal transfer senaryosuna uygun ayrılmış servisler, merkezi config, keşif, gateway ve mesaj odaklı entegrasyon sunar; tutarlılık ve tekrarlanabilirlik için idempotency ve optimistic locking vurgulanmıştır. AWS EKS dağıtımı, kalıcı Postgres (PVC), kaynak isimlendirme ve duraklat/devam adımları için [AWS EKS + ECR deployment](#aws-eks--ecr-deployment) bölümüne bakın. Operasyonel ve mimari detaylar için yukarıdaki `README/` raporlarını kullanın.
