-- ============================================================
-- Telecom Usage Event Platform
-- Apache Cassandra 5.0.9
-- ============================================================

-- Keyspace
CREATE KEYSPACE telecom_usage
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': '1'
}
AND durable_writes = true;


-- ============================================================
-- Table 1: Events by Cell and Day
-- Access pattern:
-- Retrieve events for a specific cell on a specific date.
-- ============================================================

CREATE TABLE telecom_usage.events_by_cell_day (
    cell_id int,
    event_date date,
    event_time timestamp,
    msisdn text,
    data_type text,
    latitude double,
    longitude double,
    service text,
    PRIMARY KEY ((cell_id, event_date), event_time, msisdn)
)
WITH CLUSTERING ORDER BY (event_time DESC, msisdn ASC)
    AND additional_write_policy = '99p'
    AND allow_auto_snapshot = true
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND cdc = false
    AND comment = ''
    AND compaction = {
        'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy',
        'max_threshold': '32',
        'min_threshold': '4'
    }
    AND compression = {
        'chunk_length_in_kb': '16',
        'class': 'org.apache.cassandra.io.compress.LZ4Compressor'
    }
    AND memtable = 'default'
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND extensions = {}
    AND gc_grace_seconds = 864000
    AND incremental_backups = true
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99p';


-- ============================================================
-- Table 2: Events by Subscriber and Day
-- Access pattern:
-- Retrieve events for a specific subscriber on a specific date.
-- ============================================================

CREATE TABLE telecom_usage.events_by_subscriber_day (
    msisdn text,
    event_date date,
    event_time timestamp,
    cell_id int,
    data_type text,
    latitude double,
    longitude double,
    service text,
    PRIMARY KEY ((msisdn, event_date), event_time)
)
WITH CLUSTERING ORDER BY (event_time DESC)
    AND additional_write_policy = '99p'
    AND allow_auto_snapshot = true
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND cdc = false
    AND comment = ''
    AND compaction = {
        'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy',
        'max_threshold': '32',
        'min_threshold': '4'
    }
    AND compression = {
        'chunk_length_in_kb': '16',
        'class': 'org.apache.cassandra.io.compress.LZ4Compressor'
    }
    AND memtable = 'default'
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND extensions = {}
    AND gc_grace_seconds = 864000
    AND incremental_backups = true
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99p';
