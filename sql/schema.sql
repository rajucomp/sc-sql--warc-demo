--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

-- StormCrawler SQL Schema for MySQL
-- This schema is used for URL status tracking and metrics

CREATE DATABASE IF NOT EXISTS crawl;
USE crawl;

-- URLs table for tracking crawl status
CREATE TABLE IF NOT EXISTS urls (
    url VARCHAR(512) NOT NULL,
    status VARCHAR(16) DEFAULT 'DISCOVERED',
    nextfetchdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT,
    bucket SMALLINT DEFAULT 0,
    host VARCHAR(128),
    PRIMARY KEY(url)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Indexes for efficient querying
CREATE INDEX idx_urls_bucket ON urls(bucket);
CREATE INDEX idx_urls_nextfetchdate ON urls(nextfetchdate);
CREATE INDEX idx_urls_host ON urls(host);
CREATE INDEX idx_urls_status ON urls(status);

-- Metrics table for storing crawler metrics
CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    srcComponentId VARCHAR(128),
    srcTaskId INT,
    srcWorkerHost VARCHAR(128),
    srcWorkerPort INT,
    name VARCHAR(128),
    value DOUBLE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Index for metrics queries
CREATE INDEX idx_metrics_timestamp ON metrics(timestamp);
CREATE INDEX idx_metrics_name ON metrics(name);

-- Optional: Content table for indexing (if using SQLIndexer)
CREATE TABLE IF NOT EXISTS content (
    url VARCHAR(512) NOT NULL,
    title VARCHAR(512),
    content MEDIUMTEXT,
    host VARCHAR(128),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(url)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Grant privileges to crawler user
-- Note: The user is created in docker-compose with environment variables
GRANT ALL PRIVILEGES ON crawl.* TO 'crawler'@'%';
FLUSH PRIVILEGES;

