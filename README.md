# Telecom Usage Event Platform | Apache Cassandra

A telecom usage data project built with Apache Cassandra, focusing on query-driven data modeling, partition design, concurrent data ingestion, and query validation.

Using a synthetic mobile usage dataset from Nairobi, Kenya, this project explores how Cassandra data models can be designed around specific access patterns rather than a single generalized table.

---

## Project Overview

The project covers the complete workflow of working with a telecom event dataset:

- Dataset inspection and validation
- Query-driven Cassandra data modeling
- Partition key and clustering key design
- Python-based concurrent data ingestion
- Prepared statements
- Query execution and validation
- Partition distribution and inspection

Two Cassandra tables are designed to support different retrieval requirements. Both contain the same events but organize them differently to support subscriber-based and cell-based queries.

---

## Dataset

| Attribute | Value |
|---|---|
| Source | ITU Synthetic Mobile Dataset |
| Location | Nairobi, Kenya |
| Period | February 2026 |
| Subscribers | 3,000 |
| Total events | 1,072,608 |
| Event types | CDR and IPDR |
| Network services | 2G, 3G, and 4G |
| Dataset type | Synthetic |

The dataset contains synthetic mobile network usage events and is intended for development, learning, and experimentation. It does not represent real subscriber records from a telecom operator.

### Dataset Source

[ITU Synthetic Mobile Dataset](https://www.itu.int/en/ITU-D/Statistics/Documents/bigdata/MPD_sample_synthetic_ken_3000subs.zip)

The original dataset is kept locally and excluded from Git.

---

## Technology Stack

- Ubuntu 24.04
- Python 3.12
- Pandas
- Apache Cassandra 5.0.9
- Cassandra Python Driver 3.30.1
- CQL
- JupyterLab

---

## Data Modeling

Cassandra data modeling starts with the queries the application needs to support.

Instead of relying on one table for different access patterns, this project uses two tables. Each table is designed around its own partition key and retrieval requirements.

### 1. Events by Subscriber and Day

**Table:** `events_by_subscriber_day`

Retrieves a subscriber's events for a specific date, ordered from newest to oldest.

```sql
CREATE TABLE telecom_usage.events_by_subscriber_day (
    msisdn TEXT,
    event_date DATE,
    event_time TIMESTAMP,
    cell_id INT,
    latitude DOUBLE,
    longitude DOUBLE,
    data_type TEXT,
    service TEXT,
    PRIMARY KEY ((msisdn, event_date), event_time)
)
WITH CLUSTERING ORDER BY (event_time DESC);
```

**Primary Key Design**

- Partition Key: `msisdn`, `event_date`
- Clustering Key: `event_time`
- Clustering Order: Descending

The subscriber and date determine the partition. Events within that partition are stored in time order, allowing recent events to be retrieved first.

### 2. Events by Cell and Day

**Table:** `events_by_cell_day`

Retrieves events recorded by a specific cell on a given date.

```sql
CREATE TABLE telecom_usage.events_by_cell_day (
    cell_id INT,
    event_date DATE,
    event_time TIMESTAMP,
    msisdn TEXT,
    latitude DOUBLE,
    longitude DOUBLE,
    data_type TEXT,
    service TEXT,
    PRIMARY KEY ((cell_id, event_date), event_time, msisdn)
)
WITH CLUSTERING ORDER BY (event_time DESC, msisdn ASC);
```

**Primary Key Design**

- Partition Key: `cell_id`, `event_date`
- Clustering Keys: `event_time`, `msisdn`
- Clustering Order: `event_time DESC`, `msisdn ASC`

The cell and date identify the partition. Events are ordered by time, with `msisdn` providing an additional clustering column to distinguish events sharing the same cell and timestamp.

### Why Two Tables?

Cassandra is designed around query-specific data modeling.

The same event is stored in two tables because subscriber-based retrieval and cell-based retrieval require different partition keys.

This is intentional denormalization. It avoids depending on relational-style joins to support these access patterns and allows each table to be queried using its complete partition key.

---

## Data Ingestion

Data ingestion was implemented in Python using the Cassandra Python Driver.

The ingestion process uses:

- Prepared Statements
- `ThreadPoolExecutor`
- Multithreaded concurrent ingestion
- Individual `session.execute()` calls
- 32 worker threads
- A bounded submission queue of up to 64 pending tasks

Each event is inserted individually into both Cassandra tables.

Concurrency is managed through Python threads, while each worker executes synchronous Cassandra driver calls. The bounded task submission approach limits the number of outstanding tasks rather than submitting the entire dataset to memory at once.

This implementation does not use Cassandra Batch INSERTs or native asynchronous driver execution.

---

## Data Validation

Validation was performed throughout the workflow to check the source dataset, data model, ingestion process, and query results.

### Dataset Validation

- Dataset dimensions and schema inspection
- Column data type checks
- Missing-value checks
- Duplicate-record checks
- Timestamp validation
- Geographic coordinate range checks
- Subscriber and event statistics

### Data Model Validation

- Primary key uniqueness checks against the source dataset
- Partition key selection
- Clustering key selection
- Logical partition distribution analysis

### Ingestion Validation

- Cassandra connectivity
- Prepared statement execution
- Test inserts into both tables
- Sample ingestion
- Full dataset ingestion process
- Cassandra write statistics inspection
- Sample partition count comparisons against the source dataset

### Query Validation

Both query patterns were executed against Cassandra and compared with the corresponding source records.

The subscriber-based sample retrieval was validated against the original dataset, and the retrieved results matched.

Cell-based retrieval was also executed and inspected directly in Cassandra.

Validation focused on the selected query patterns and inspected partitions rather than relying on a full-table `COUNT(*)` operation.

---

## Partition Distribution

Logical partition distribution was calculated from the original dataset using the partition keys defined for each table.

| Cassandra Table | Partition Key | Logical Partition Count |
|---|---|---:|
| `events_by_subscriber_day` | `msisdn`, `event_date` | 77,711 |
| `events_by_cell_day` | `cell_id`, `event_date` | 342,168 |

### Largest Inspected Partitions

| Table | Partition | Event Count |
|---|---|---:|
| `events_by_subscriber_day` | `subscribers_02091`, 2026-02-13 | 289 |
| `events_by_cell_day` | `cell_id` 30701, 2026-02-28 | 293 |

The largest partitions were retrieved directly from Cassandra and their record counts were checked against the source dataset.

Partition counts shown above are logical counts derived from the source data. They are not exact measurements of Cassandra's physical storage layout.

---
```
## Project Structure

telecom-usage-cassandra/
├── cassandra/
│   └── schema.cql
├── data/
│   └── raw/                                      # Excluded from Git
│       ├── itu_synthetic_cdr_core.zip
│       └── MPD_sample_synthetic_ken_3000subs.csv
├── notebooks/
│   ├── 01_dataset_validation.ipynb
│   ├── 02_cassandra_data_modeling.ipynb
│   ├── 03_python_cassandra_data_ingestion.ipynb
│   └── 04_cassandra_queries.ipynb
├── .gitignore
└── README.md
```
### Notebooks

| Notebook | Description |
|---|---|
| `01_dataset_validation.ipynb` | Dataset inspection, quality checks, and validation |
| `02_cassandra_data_modeling.ipynb` | Query patterns, primary keys, and partition design |
| `03_python_cassandra_data_ingestion.ipynb` | Python connectivity, prepared statements, and concurrent ingestion |
| `04_cassandra_queries.ipynb` | Query execution, source comparisons, and partition inspection |

---

## Cassandra Configuration

| Setting | Value |
|---|---|
| Keyspace | `telecom_usage` |
| Replication Strategy | `SimpleStrategy` |
| Replication Factor | `1` |
| Deployment | Single-node local instance |

The Cassandra environment is configured for local development and experimentation. It is not intended to represent a production, highly available cluster.

---

## Limitations

- Synthetic dataset rather than real operator data
- Single-node Cassandra deployment
- Replication factor of 1
- No multi-node or cluster failure testing
- No formal ingestion throughput benchmark
- No dashboard or visualization layer
- Query support limited to the access patterns implemented in the project

---

## Key Concepts Explored

- NoSQL data modeling
- Apache Cassandra architecture and query-driven design
- Partition keys and clustering keys
- Composite primary keys
- Denormalization
- Prepared Statements
- Concurrent data ingestion with Python
- ThreadPoolExecutor
- Cassandra data retrieval
- Source-to-database validation
- Logical partition distribution and inspection

---
