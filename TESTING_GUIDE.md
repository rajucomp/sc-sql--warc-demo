# Testing Guide: Validating Your StormCrawler Changes

This guide will help you test your modified Apache StormCrawler code using the sc-warc-demo project.

## Overview

You have two main options for testing your StormCrawler changes:

### Option A: Test with WARC Module (Simpler - Recommended First)
Keep the existing WARC configuration and just replace the StormCrawler dependency with your modified version.

### Option B: Test with SQL Module (As Suggested by @rajucomp)
Replace the WARC module with the SQL module for persistence to a database.

---

## Prerequisites

- ✅ Docker and Docker Compose installed
- ✅ Java 17 installed
- ✅ Maven installed
- ✅ Your modified StormCrawler project built and available

---

## OPTION A: Testing with WARC Module (Quick Validation)

This is the fastest way to validate your changes work correctly.

### Step 1: Build Your Modified StormCrawler

First, navigate to your modified StormCrawler project and build it:

```bash
cd /path/to/your/stormcrawler
mvn clean install -DskipTests
```

This installs your modified StormCrawler JARs into your local Maven repository (~/.m2/repository).

### Step 2: Update sc-warc-demo pom.xml

You need to tell the demo project to use your local StormCrawler build instead of the official release.

**Option 2a: Use SNAPSHOT version**

If your StormCrawler build uses a SNAPSHOT version (e.g., 3.6.0-SNAPSHOT), update the version in `pom.xml`:

```xml
<properties>
    <stormcrawler.version>3.6.0-SNAPSHOT</stormcrawler.version>
    <!-- ... other properties ... -->
</properties>
```

**Option 2b: Use a custom version**

Alternatively, you can change the version in your StormCrawler pom.xml to something unique (e.g., 3.5.0-CUSTOM) before building, then reference that version here.

### Step 3: Build the Demo Project

```bash
cd /Users/raju.gupta/code/sc-warc-demo
mvn clean package
```

This creates: `target/stormcrawler-warc-1.0-SNAPSHOT.jar`

### Step 4: Start the Storm Cluster

```bash
docker compose up -d
```

Wait a few seconds for the cluster to start. Verify it's running:

```bash
docker compose ps
```

You should see containers for Storm Nimbus, Supervisor, UI, and URLFrontier.

### Step 5: Inject Seed URLs

```bash
java -cp target/stormcrawler-warc-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutURLs -f seeds.txt
```

### Step 6: Submit the Topology

```bash
docker run --network sc-warc-demo_default -it \
--rm \
-v "$(pwd)/crawler-conf.yaml:/apache-storm/crawler-conf.yaml" \
-v "$(pwd)/crawler.flux:/apache-storm/crawler.flux" \
-v "$(pwd)/target/stormcrawler-warc-1.0-SNAPSHOT.jar:/apache-storm/stormcrawler-warc-1.0-SNAPSHOT.jar" \
storm:latest \
storm jar stormcrawler-warc-1.0-SNAPSHOT.jar org.apache.storm.flux.Flux --remote crawler.flux
```

**Note:** The network name might be different. Check with `docker network ls` and adjust if needed.

### Step 7: Monitor the Crawl

- **Storm UI:** http://localhost:8080
- **Logs:** Check the Storm UI for topology logs
- **WARC Files:** Should appear in `./data/warc/` directory

### Step 8: Verify Your Changes

Check the logs and WARC output to ensure your modifications are working as expected.

### Step 9: Stop the Topology

From the Storm UI, you can kill the topology, or use:

```bash
docker exec -it <nimbus-container-id> storm kill warc-crawler
```

### Step 10: Clean Up

```bash
docker compose down
```

---

## OPTION B: Testing with SQL Module (Recommended by @rajucomp)

This approach replaces the WARC persistence with SQL database persistence.

### Prerequisites for SQL Testing

You'll need to:
1. Add a database (MySQL/PostgreSQL) to docker-compose.yml
2. Update pom.xml to use stormcrawler-sql instead of stormcrawler-warc
3. Modify crawler.flux to use SQL bolts
4. Configure database connection in crawler-conf.yaml

**Detailed steps for Option B are provided in TESTING_GUIDE_SQL.md**

---

## Troubleshooting

### Issue: "No such network"
- Run `docker network ls` to find the correct network name
- Update the `--network` parameter in the docker run command

### Issue: "Connection refused" when injecting URLs
- Ensure the Storm cluster is fully started
- Check `docker compose ps` to verify all containers are running
- Wait 30-60 seconds after `docker compose up` before injecting URLs

### Issue: Modified code not being used
- Verify your StormCrawler was installed to local Maven repo: `ls ~/.m2/repository/org/apache/stormcrawler/`
- Check the version matches in both projects
- Try `mvn clean package -U` to force update dependencies

### Issue: Topology fails to start
- Check Storm UI logs at http://localhost:8080
- Verify all required configuration files are present
- Check for Java version compatibility (should be Java 17)

---

## Next Steps

After successful testing:
1. Review the crawl results
2. Check logs for any errors or warnings related to your changes
3. Verify the behavior matches your expectations
4. Run additional test crawls with different seed URLs if needed
5. Document any issues or unexpected behavior

---

## Questions?

If you encounter issues, check:
- Storm UI logs: http://localhost:8080
- Docker container logs: `docker compose logs -f`
- Your StormCrawler build logs

