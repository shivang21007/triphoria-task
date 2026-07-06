# Triphoria — DevOps Assessment

Infrastructure-as-code (Terraform on AWS) plus local MySQL reliability exercises: migrations, seed data, query indexing, backup, and restore.

**Stack:** Terraform, AWS (VPC, ALB, ECS Fargate, RDS MySQL), Docker Compose, MySQL 8, GitHub Actions, Bash.

---

## Repository layout

```
infra/
  modules/network/   # VPC, subnets, NAT, security groups
  modules/ecs/       # ALB, ECS Fargate cluster/service (nginx placeholder)
  modules/rds/       # Private RDS MySQL
  envs/dev/          # Smaller sizing, short backups, no deletion protection
  envs/prod/         # Larger sizing, longer backups, deletion protection on
db/migrations/       # Schema + index SQL
scripts/             # seed, backup, restore
docker-compose.yml   # Local MySQL
```

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- MySQL client tools (`mysql`, `mysqldump`) on your host for scripts
- (Optional) AWS credentials if you want a live `terraform plan` against AWS APIs

---

## Part 1–2: Terraform

### Validate locally (no AWS apply required)

```bash
cd infra/envs/dev
terraform fmt -recursive ../../..
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=terraform.tfvars.example
```

Repeat for `infra/envs/prod`.

### Environment differences

| Setting | dev | prod |
|---------|-----|------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| NAT | Single NAT GW | NAT per AZ |
| RDS class | db.t3.micro | db.t3.small |
| RDS backup retention | 3 days | 14 days |
| RDS deletion protection | false | true |
| RDS Multi-AZ | false | true |
| ECS tasks | 1 × 256 CPU / 512 MB | 2 × 512 CPU / 1024 MB |

### Remote state (production pattern)

Copy `backend.hcl.example` to `backend.hcl`, create the S3 bucket and DynamoDB lock table, then:

```bash
terraform init -backend-config=backend.hcl
```

Uncomment `backend "s3" {}` in `providers.tf` before using remote state.

### Architecture

```
Internet → ALB (public subnets) → ECS Fargate (private subnets) → RDS MySQL (private subnets)
```

Security groups enforce least privilege: ALB accepts 80/443 from the internet; ECS accepts app traffic only from ALB; RDS accepts MySQL (3306) only from ECS.

---

## Part 3: CI (GitHub Actions)

On pull requests touching `infra/**`, the workflow runs `terraform fmt`, `init`, `validate`, and `plan` for both `dev` and `prod`, then posts the plan output as a PR comment.

---

## Part 4–6: Local MySQL

### Start database

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Migrations in `db/migrations/` run automatically on the **first** container start (empty volume). To reset:

```bash
docker compose down -v
docker compose up -d
```

### Seed data

```bash
chmod +x scripts/*.sh
./scripts/seed.sh
```

Creates 120 bookings across multiple cities, organizations, and statuses, plus booking events for every third booking.

### Query optimization

Target query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY org_id, status;
```

**Index added** (`db/migrations/002_add_indexes.sql`):

```sql
CREATE INDEX idx_hotel_bookings_city_created_org_status
  ON hotel_bookings (city, created_at, org_id, status);
```

**Why this index:** The query filters on `city` (equality) and `created_at` (range), then groups by `org_id` and `status`. A composite index with `city` first, then `created_at`, then the grouping columns lets MySQL satisfy the `WHERE` clause from the index and avoid a full table scan.

Verify with `EXPLAIN`:

```bash
docker compose exec db mysql -utriphoria -ptriphoria triphoria -e "
EXPLAIN SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY org_id, status\G
"
```

Look for `key = idx_hotel_bookings_city_created_org_status` and a low `rows` estimate.

---

## Backup and restore

### Backup

```bash
./scripts/backup.sh
```

Creates a timestamped gzip dump under `backups/`, e.g. `backups/triphoria_20260706_120000.sql.gz`.

### Restore (into a fresh database)

```bash
./scripts/restore.sh
# or: ./scripts/restore.sh backups/triphoria_YYYYMMDD_HHMMSS.sql.gz
```

Restores into `triphoria_restore` (configurable via `RESTORE_DATABASE` in `.env`) and prints row counts for both the source and restored databases.

### Verify restore succeeded

1. Row counts for `hotel_bookings` and `booking_events` match between `triphoria` and `triphoria_restore`.
2. Spot-check a booking:

```bash
docker compose exec db mysql -utriphoria -ptriphoria -e "
SELECT id, city, status, amount FROM triphoria.hotel_bookings LIMIT 3;
SELECT id, city, status, amount FROM triphoria_restore.hotel_bookings LIMIT 3;
"
```

---

## Submission checklist

- [x] Terraform infrastructure code (ALB → ECS → RDS)
- [x] `dev` and `prod` environment examples
- [x] Docker Compose MySQL setup
- [x] SQL migration files
- [x] Seed data script
- [x] `scripts/backup.sh` and `scripts/restore.sh`
- [x] README with setup and verification steps

---

## Review commands (quick copy)

```bash
# Terraform
cd infra/envs/dev && terraform fmt -recursive ../../.. && terraform init -backend=false && terraform validate && terraform plan -refresh=false -var-file=terraform.tfvars.example

# Database
docker compose up -d
./scripts/seed.sh
./scripts/backup.sh
./scripts/restore.sh
```
