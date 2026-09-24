# hotel-infra-assessment

Terraform setup for an ALB → ECS Fargate → RDS stack on AWS, plus a local
Postgres setup with migrations, seed data, and backup/restore scripts.

Terraform docs are below the database section (work in progress).

### Local database
### Requirements

- Docker with Docker Compose v2
- bash (scripts tested on macOS)

### Start the database

```bash
docker compose up -d
```

On the first start, Postgres runs the files mounted into
`/docker-entrypoint-initdb.d/` in this order:

1. `db/migrations/001_schema.sql` creates `hotel_bookings` and `booking_events`
2. `db/migrations/002_indexes.sql` creates the indexes
3. `db/seed/seed.sql` inserts 200 bookings and their events

###### these scripts only run when the data volume is empty. If you already started the container before, reset it first:

```bash
docker compose down -v
docker compose up -d
```

# Check that everything loaded:

```bash
docker exec -it hotel-db psql -U hotel -d hotel -c "\dt"
docker exec -it hotel-db psql -U hotel -d hotel -c "SELECT city, COUNT(*) FROM hotel_bookings GROUP BY city;"
```

### Seed data

`seed.sql` uses `generate_series` to create 200 bookings spread across
4 orgs, 5 cities (delhi, mumbai, bangalore, goa, jaipur) and 4 statuses
(pending, confirmed, cancelled, completed). `created_at` is random within
the last 90 days, so the "last 30 days" query only matches part of the data.

Every booking gets a `booking_created` event. Bookings that are not
`pending` get a second event for their status.

### Query optimization

Query to optimize:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Index added:

```sql
CREATE INDEX idx_bookings_city_created
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

Why this index:

- `city` is an equality filter and `created_at` is a range filter. Putting
  the equality column first lets Postgres jump to the `delhi` rows and then
  read only the last 30 days within them. The reverse order
  `(created_at, city)` would scan every city's recent rows first.
- `org_id`, `status` and `amount` are added with `INCLUDE`, so the query
  can be answered from the index alone (index-only scan) without reading
  the table.

I also added an index on `booking_events(booking_id)`, since Postgres does
not create one for foreign keys automatically and events are always looked
up by booking.

To see the plan:

```bash
docker exec -it hotel-db psql -U hotel -d hotel
```

```sql
EXPLAIN ANALYZE
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

With only 200 rows, the planner may still pick a sequential scan because
reading a small table directly is cheaper. To confirm the index works, run
`SET enable_seqscan = off;` in the same session and repeat the query. The
plan should show `Index Only Scan using idx_bookings_city_created`. On a
real table with lots of rows, the planner picks the index on its own.

### Backup

```bash
./scripts/backup.sh
```

Runs `pg_dump` inside the container and saves a plain SQL dump to
`backups/hotel_YYYYMMDD_HHMMSS.sql`. The `backups/` folder is in
`.gitignore`.

### Restore

```bash
./scripts/restore.sh                         # uses the latest backup
./scripts/restore.sh backups/<file>.sql      # or a specific one
```

The script drops and recreates a separate database called `hotel_restore`,
then loads the dump into it. The original `hotel` database is not touched,
so you can compare the two.

### Verifying the restore

The restore script prints row counts from both databases at the end:

```
  hotel_bookings: original=200 restored=200
  booking_events: original=350 restored=350
```

(The events count changes a bit on each fresh seed because statuses are random.)

Matching counts mean the data came back. You can also check manually:

```bash
# tables and indexes exist in the restored database
docker exec -it hotel-db psql -U hotel -d hotel_restore -c "\dt"
docker exec -it hotel-db psql -U hotel -d hotel_restore -c "\di"

# the report query returns the same result in both
docker exec -it hotel-db psql -U hotel -d hotel -c \
  "SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status ORDER BY 1, 2;"

docker exec -it hotel-db psql -U hotel -d hotel_restore -c \
  "SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status ORDER BY 1, 2;"
```

### Full test from scratch

```bash
docker compose down -v
docker compose up -d
sleep 5   # wait for init scripts to finish
./scripts/backup.sh
./scripts/restore.sh
```
## Terraform

Internet -> ALB -> ECS Fargate (nginx) -> RDS Postgres, in ap-south-1.

ALB and NAT are in public subnets. ECS tasks and RDS are in private subnets.

Security groups:
- alb sg: port 80 from anywhere
- app sg: port 80 only from alb sg
- db sg: port 5432 only from app sg

RDS has `publicly_accessible = false` and the master password is managed
by RDS in Secrets Manager, so there is no password in the code.

### dev vs prod

| | dev | prod |
|---|---|---|
| vpc | 10.10.0.0/16 | 10.20.0.0/16 |
| ecs task | 256 cpu / 512 mb, 1 task | 512 cpu / 1024 mb, 2 tasks |
| rds | db.t4g.micro, 20gb | db.t4g.medium, 50gb |
| multi az | no | yes |
| backup retention | 1 day | 14 days |
| deletion protection | false | true |
| final snapshot | skipped | taken |

Values are in each env's `terraform.tfvars`.

### Running plan

```bash
cd infra/envs/dev    # or prod
terraform fmt -check -recursive ../../
terraform init
terraform validate
terraform plan -refresh=false
```

No AWS account needed. `plan_only` is `true` by default, which makes the
provider use mock credentials and skip the account checks. For a real
deploy set `plan_only = false` and use normal AWS credentials.

State is local for now. Each env's `backend.tf` has the S3 backend config
commented out (separate state key per env).

### CI

`.github/workflows/terraform.yml` runs on pull requests that touch `infra/`.
It runs fmt, init, validate and plan for dev and prod, and posts the plan
as a PR comment. Example: PR #1.

### Things I'd add for a real setup

- one NAT gateway per AZ (right now there is one to keep cost down)
- HTTPS listener with an ACM certificate
- S3 backend for state
- autoscaling for the ECS service
