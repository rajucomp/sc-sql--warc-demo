# StormCrawler SQL Demo

This project demonstrates **StormCrawler with SQL persistence** using MySQL for URL status tracking and metrics storage. It was adapted from the StormCrawler Maven Archetype to showcase the SQL module integration.

## Features

- **SQL-based URL persistence**: URL statuses are stored in MySQL instead of WARC files
- **SQL MetricsConsumer**: Crawler metrics are persisted to MySQL for monitoring
- **URLFrontier integration**: URL scheduling via the URLFrontier service
- **Docker-based deployment**: Complete infrastructure including Storm, MySQL, and URLFrontier

## Prerequisites

- **Docker** and **Docker Compose** installed on your system
- **Java 17** and **Maven** for building the project
- **MySQL client** (optional, for direct database queries)

## Architecture

The setup includes the following Docker containers:

| Container | Purpose | Port |
|-----------|---------|------|
| `nimbus` | Storm Nimbus (master) | - |
| `supervisor` | Storm Supervisor (worker) | - |
| `ui` | Storm UI | 8080 |
| `zookeeper` | Storm coordination | 2181 |
| `urlfrontier` | URL scheduling service | 7071 |
| `mysql` | SQL persistence (URL status & metrics) | 3306 |

## Starting the Infrastructure

Start all services using Docker Compose:

```sh
docker compose up -d
```

Wait for MySQL to be healthy (this may take 30-60 seconds):

```sh
docker ps --format "table {{.Names}}\t{{.Status}}"
```

You should see `mysql` with status `Up X minutes (healthy)`.

> **Note:** This setup uses an **in-memory URLFrontier**. URL queue state will be lost when containers are restarted. However, **URL statuses are persisted in MySQL** and will survive restarts.

The **Storm UI** is available at [http://localhost:8080](http://localhost:8080).

## Compilation

Build the uberjar:

```sh
mvn clean package
```

This creates `target/stormcrawler-sql-1.0-SNAPSHOT.jar`.

## URL Injection

Inject seed URLs into URLFrontier using the provided [client](https://github.com/crawler-commons/url-frontier/tree/master/client):

```sh
java -cp target/stormcrawler-sql-1.0-SNAPSHOT.jar \
  crawlercommons.urlfrontier.client.Client PutURLs -f seeds.txt
```

Here, `seeds.txt` should contain one URL per line.

## Running the Crawl

Submit the Flux topology to Storm:

```sh
docker run --network sc-warc-demo_default -it \
  --rm \
  -v "$(pwd)/crawler-conf.yaml:/apache-storm/crawler-conf.yaml" \
  -v "$(pwd)/crawler.flux:/apache-storm/crawler.flux" \
  -v "$(pwd)/target/stormcrawler-sql-1.0-SNAPSHOT.jar:/apache-storm/stormcrawler-sql-1.0-SNAPSHOT.jar" \
  storm:latest \
  storm jar stormcrawler-sql-1.0-SNAPSHOT.jar org.apache.storm.flux.Flux --remote crawler.flux
```

> **Note:** If unsure of the Docker network name, run `docker network ls` and adjust the `--network` parameter accordingly.

## Monitoring

### Storm UI

Access the Storm UI at [http://localhost:8080](http://localhost:8080) to monitor:
- Topology status and uptime
- Bolt/Spout statistics
- Worker logs

### URLFrontier Statistics

Check URLFrontier queue status:

```sh
java -cp target/stormcrawler-sql-1.0-SNAPSHOT.jar \
  crawlercommons.urlfrontier.client.Client -t localhost -p 7071 GetStats
```

List active queues:

```sh
java -cp target/stormcrawler-sql-1.0-SNAPSHOT.jar \
  crawlercommons.urlfrontier.client.Client -t localhost -p 7071 ListQueues
```

## Verifying SQL Persistence

### Connect to MySQL

```sh
docker exec -it mysql mysql -ucrawler -pcrawler crawl
```

### Check URL Status Distribution

```sql
SELECT status, COUNT(*) as count FROM urls GROUP BY status;
```

### View All Tracked URLs

```sql
SELECT url, status, nextfetchdate, host FROM urls;
```

### Check Crawler Metrics

```sql
SELECT * FROM metrics ORDER BY timestamp DESC LIMIT 20;
```

### Database Schema

The SQL module uses three tables:

| Table | Purpose |
|-------|---------|
| `urls` | URL status tracking (url, status, nextfetchdate, metadata, host) |
| `metrics` | Crawler performance metrics |
| `content` | Optional content storage |

## Configuration Files

| File | Purpose |
|------|---------|
| `crawler.flux` | Storm topology definition |
| `crawler-conf.yaml` | Crawler configuration (SQL connection, fetcher settings) |
| `sql/schema.sql` | MySQL database schema |
| `docker-compose.yml` | Infrastructure definition |

## SQL Connection Settings

The crawler connects to MySQL with these settings (configured in `crawler-conf.yaml`):

```yaml
sql.connection:
  url: "jdbc:mysql://mysql:3306/crawl?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
  user: "crawler"
  password: "crawler"

sql.status.table: "urls"
sql.metrics.table: "metrics"
```

## Stopping the Crawl

Kill the topology:

```sh
docker run --network sc-warc-demo_default -it --rm storm:latest \
  storm kill sql-crawler
```

Stop all containers:

```sh
docker compose down
```

To also remove MySQL data:

```sh
docker compose down -v
```
