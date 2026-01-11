# Testing Guide: StormCrawler SQL Module

This guide helps you test your modified StormCrawler SQL module using this demo project.

## Prerequisites

- Docker and Docker Compose installed
- Java 17 installed
- Maven installed
- Your modified StormCrawler SQL module built locally (`mvn clean install` in your StormCrawler project)

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ URLFrontier │────▶│   Storm     │────▶│   MySQL     │
│   (Spout)   │     │  Topology   │     │ (Status DB) │
└─────────────┘     └─────────────┘     └─────────────┘
```

The crawler uses:
- **URLFrontier**: For URL scheduling and deduplication
- **MySQL**: For persisting URL status via `SQLStatusUpdaterBolt`
- **Storm**: For distributed processing

## Step-by-Step Testing

### Step 1: Verify Your Local StormCrawler Build

Ensure your modified StormCrawler is installed in your local Maven repository:

```bash
# In your StormCrawler project directory
mvn clean install -DskipTests
```

Verify the SQL module is available:
```bash
ls ~/.m2/repository/org/apache/stormcrawler/stormcrawler-sql/3.5.1-SNAPSHOT/
```

### Step 2: Build the Demo Project

```bash
cd /Users/raju.gupta/code/sc-warc-demo
mvn clean package -DskipTests
```

### Step 3: Start the Infrastructure

```bash
docker compose up -d
```

Wait for all services to be healthy (especially MySQL):
```bash
docker compose ps
# Wait until mysql shows "healthy" status
```

### Step 4: Verify MySQL is Ready

```bash
docker exec -it mysql mysql -ucrawler -pcrawler -e "SHOW TABLES FROM crawl;"
```

Expected output:
```
+----------------+
| Tables_in_crawl|
+----------------+
| content        |
| metrics        |
| urls           |
+----------------+
```

### Step 5: Inject Seed URLs

```bash
docker run --rm --network sc-warc-demo_default \
  crawlercommons/url-frontier \
  PutURLs -f urlfrontier -p 7071 < seeds.txt
```

### Step 6: Submit the Topology

```bash
docker run --rm --network sc-warc-demo_default \
  -v $(pwd)/target/stormcrawler-sql-1.0-SNAPSHOT.jar:/topology.jar \
  storm:latest storm jar /topology.jar org.apache.storm.flux.Flux \
  --remote --filter /topology.jar sql-crawler
```

Note: The JAR name changed from `stormcrawler-warc` to `stormcrawler-sql`.

### Step 7: Monitor the Crawl

**Storm UI:** http://localhost:8080

**Check URL status in MySQL:**
```bash
docker exec -it mysql mysql -ucrawler -pcrawler -e "SELECT url, status, nextfetchdate FROM crawl.urls LIMIT 10;"
```

**Check metrics:**
```bash
docker exec -it mysql mysql -ucrawler -pcrawler -e "SELECT name, value, timestamp FROM crawl.metrics ORDER BY timestamp DESC LIMIT 10;"
```

### Step 8: Verify Your SQL Changes

Look for evidence that your modifications are working:

```bash
# Check URL count by status
docker exec -it mysql mysql -ucrawler -pcrawler -e "SELECT status, COUNT(*) FROM crawl.urls GROUP BY status;"

# Check recent activity
docker exec -it mysql mysql -ucrawler -pcrawler -e "SELECT * FROM crawl.urls ORDER BY nextfetchdate DESC LIMIT 5;"
```

### Step 9: Stop the Topology

From Storm UI or:
```bash
docker exec -it nimbus storm kill sql-crawler
```

### Step 10: Clean Up

```bash
docker compose down -v  # -v removes the MySQL data volume
```

## Troubleshooting

### MySQL Connection Issues
```bash
# Check MySQL logs
docker logs mysql

# Test connection manually
docker exec -it mysql mysql -ucrawler -pcrawler crawl
```

### Topology Fails to Start
```bash
# Check Storm supervisor logs
docker logs supervisor
```

### No Data in MySQL
- Verify URLFrontier has URLs: Check Storm UI spout metrics
- Check for errors in Storm logs
- Ensure MySQL healthcheck passed before submitting topology

## Useful MySQL Queries

```sql
-- URL status distribution
SELECT status, COUNT(*) as count FROM crawl.urls GROUP BY status;

-- Recent fetch activity
SELECT url, status, nextfetchdate FROM crawl.urls 
WHERE status = 'FETCHED' ORDER BY nextfetchdate DESC LIMIT 10;

-- Error analysis
SELECT url, metadata FROM crawl.urls WHERE status = 'ERROR' LIMIT 5;

-- Metrics summary
SELECT name, AVG(value) as avg_value, COUNT(*) as samples 
FROM crawl.metrics GROUP BY name;
```

