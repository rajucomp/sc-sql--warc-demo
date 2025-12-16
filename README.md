This project was generated using the **StormCrawler Maven Archetype** and serves as a starting point for building your own crawler. Review the provided code and resources and adapt them as needed for your use case.

## Prerequisites

You need to have **Docker** and **Docker Compose** installed on your system.
Java 17 and **Maven** are also required for building the project.

## Starting the Storm cluster

Start the Storm cluster using Docker Compose:

```sh
docker compose up -d
```

> **Note:** This setup uses an **in-memory URLFrontier**. As a result, all queued URLs and crawl state will be lost when the Docker containers are stopped or restarted. Persistence can be enabled by reconfiguring URLFrontier if needed (consult the Apache StormCrawler documentation)

The **Storm UI** is available at [http://localhost:8080](http://localhost:8080), where you can monitor the cluster and manage or rebalance the topology.

## Compilation

Build an uberjar with:

```sh
mvn clean package
```

## URL injection

Before starting the crawl, inject seed URLs into URLFrontier using the provided [client](https://github.com/crawler-commons/url-frontier/tree/master/client):

```sh
java -cp target/stormcrawler-warc-1.0-SNAPSHOT.jar crawlercommons.urlfrontier.client.Client PutURLs -f seeds.txt
```

Here, `seeds.txt` should contain one URL per line.

## Running the crawl

You can now submit the Flux topology using the `storm` command:

```sh
docker run --network stormcrawler-warc_default -it \
--rm \
-v "$(pwd)/crawler-conf.yaml:/apache-storm/crawler-conf.yaml" \
-v "$(pwd)/crawler.flux:/apache-storm/crawler.flux" \
-v "$(pwd)/target/stormcrawler-warc-1.0-SNAPSHOT.jar:/apache-storm/stormcrawler-warc-1.0-SNAPSHOT.jar" \
storm:latest \
storm jar stormcrawler-warc-1.0-SNAPSHOT.jar org.apache.storm.flux.Flux --remote crawler.flux
```

Monitor by accessing the Storm UI at [http://localhost:8080](http://localhost:8080).

The WARC records should come into `./data` on the host system.

> **Note:** If you are unsure of the Docker network name, you can list available networks using:
>
```sh
docker network ls
```
>
> Adjust the `--network` parameter accordingly.
