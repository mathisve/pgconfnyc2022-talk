DROP TABLE IF EXISTS measurement;
CREATE TABLE measurement (
    time TIMESTAMPTZ NOT NULL,
    sensorID INT NULL,
    sensor_value REAL NULL
) PARTITION BY RANGE (time);

CREATE TABLE measurementy2022m01 PARTITION OF measurement
    FOR VALUES FROM ('2022-01-01') TO ('2022-02-01');

CREATE TABLE measurementy2022m02 PARTITION OF measurement
    FOR VALUES FROM ('2022-02-01') TO ('2022-03-01');

CREATE TABLE measurementy2022m03 PARTITION OF measurement
    FOR VALUES FROM ('2022-03-01') TO ('2022-04-01');

CREATE INDEX ON measurement (time);

INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-01-3', 2, 2.9);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-01-6', 1, 3.5);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-01-15', 3, 6.2);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-01-23', 1, 3.2);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-01-28', 2, 5.2);

INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-02-04', 3, 4.1);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-02-09', 1, 5.2);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-02-13', 2, 2.6);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-02-24', 2, 1.7);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-02-28', 1, 6.1);

INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-03-6', 3, 5.2);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-03-8', 2, 2.3);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-03-12', 1, 1.6);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-03-27', 3, 2.5);
INSERT INTO measurement (time, sensorID, sensor_value) VALUES ('2022-03-29', 2, 5.3);

SELECT tableoid, * from measurement;

--  tableoid |          time          | sensorid | sensor_value
-- ----------+------------------------+----------+--------------
--     18918 | 2022-01-03 00:00:00+00 |        2 |          2.9
--     18918 | 2022-01-06 00:00:00+00 |        1 |          3.5
--     18918 | 2022-01-15 00:00:00+00 |        3 |          6.2
--     18918 | 2022-01-23 00:00:00+00 |        1 |          3.2
--     18918 | 2022-01-28 00:00:00+00 |        2 |          5.2
--     18921 | 2022-02-04 00:00:00+00 |        3 |          4.1
--     18921 | 2022-02-09 00:00:00+00 |        1 |          5.2
--     18921 | 2022-02-13 00:00:00+00 |        2 |          2.6
--     18921 | 2022-02-24 00:00:00+00 |        2 |          1.7
--     18921 | 2022-02-28 00:00:00+00 |        1 |          6.1
--     18924 | 2022-03-06 00:00:00+00 |        3 |          5.2
--     18924 | 2022-03-08 00:00:00+00 |        2 |          2.3
--     18924 | 2022-03-12 00:00:00+00 |        1 |          1.6
--     18924 | 2022-03-27 00:00:00+00 |        3 |          2.5
--     18924 | 2022-03-29 00:00:00+00 |        2 |          5.3
-- (15 rows)

SELECT 
    tablename, indexname
FROM
    pg_indexes
WHERE
    tablename LIKE 'measurement%';

--       tablename      |              indexname
-- ---------------------+--------------------------------------
--  measurement         | measurement_time_idx
--  measurement         | measurement_sensor_value_idx
--  measurementy2022m01 | measurementy2022m01_time_idx
--  measurementy2022m01 | measurementy2022m01_sensor_value_idx
--  measurementy2022m02 | measurementy2022m02_time_idx
--  measurementy2022m02 | measurementy2022m02_sensor_value_idx
--  measurementy2022m03 | measurementy2022m03_time_idx
--  measurementy2022m03 | measurementy2022m03_sensor_value_idx
-- (8 rows)

SET enable_partition_pruning = on;

EXPLAIN ANALYZE SELECT * FROM measurement WHERE time > '2022-03-01';
--                                                                             QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Index Scan using measurementy2022m03_time_idx on measurementy2022m03 measurement  (cost=0.15..23.05 rows=617 width=16) (actual time=0.005..0.006 rows=5 loops=1)
--    Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--  Planning Time: 0.090 ms
--  Execution Time: 0.019 ms
-- (4 rows)

SET enable_partition_pruning = off;

EXPLAIN ANALYZE SELECT * FROM measurement WHERE time > '2022-03-01';
--                                                                                 QUERY PLAN
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Append  (cost=0.15..78.41 rows=1851 width=16) (actual time=0.031..0.033 rows=5 loops=1)
--    ->  Index Scan using measurementy2022m01_time_idx on measurementy2022m01 measurement_1  (cost=0.15..23.05 rows=617 width=16) (actual time=0.013..0.013 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurementy2022m02_time_idx on measurementy2022m02 measurement_2  (cost=0.15..23.05 rows=617 width=16) (actual time=0.004..0.004 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurementy2022m03_time_idx on measurementy2022m03 measurement_3  (cost=0.15..23.05 rows=617 width=16) (actual time=0.013..0.014 rows=5 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--  Planning Time: 0.123 ms
--  Execution Time: 0.053 ms
-- (9 rows)

INSERT INTO measurement (time, sensorID, sensor_value) SELECT 
    (timestamptz '2022-01-01' + random() * (timestamptz '2022-04-01' - timestamptz '2022-01-01')), 
    generate_series(0,500000),
    random()*2-random();