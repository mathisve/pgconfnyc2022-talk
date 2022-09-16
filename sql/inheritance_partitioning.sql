DROP TABLE IF EXISTS measurement_y2022m01;
DROP TABLE IF EXISTS measurement_y2022m02;
DROP TABLE IF EXISTS measurement_y2022m03;

DROP TABLE IF EXISTS measurement;
CREATE TABLE measurement (
    time TIMESTAMPTZ NOT NULL,
    sensorID INT NULL,
    sensor_value REAL NULL
);


CREATE TABLE measurement_y2022m01 () INHERITS (measurement);
CREATE TABLE measurement_y2022m02 () INHERITS (measurement);
CREATE TABLE measurement_y2022m03 () INHERITS (measurement);

CREATE INDEX ON measurement_y2022m01 (time);
CREATE INDEX ON measurement_y2022m02 (time);
CREATE INDEX ON measurement_y2022m03 (time);

SELECT 
    tablename, indexname
FROM
    pg_indexes
WHERE
    tablename LIKE 'measurement%';

--       tablename      |              indexname
-- ---------------------+--------------------------------------
--  measurementy2022m01 | measurementy2022m01_time_idx
--  measurementy2022m02 | measurementy2022m02_time_idx
--  measurementy2022m03 | measurementy2022m03_time_idx


CREATE OR REPLACE FUNCTION measurement_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF ( NEW.time >= DATE '2022-01-01' AND
         NEW.time < DATE '2022-02-01' ) THEN
        INSERT INTO measurement_y2022m01 VALUES (NEW.*);
    ELSIF ( NEW.time >= DATE '2022-02-01' AND
            NEW.time < DATE '2022-03-01' ) THEN
        INSERT INTO measurement_y2022m02 VALUES (NEW.*);
    ELSIF ( NEW.time >= DATE '2022-03-01' AND
            NEW.time < DATE '2022-04-01' ) THEN
        INSERT INTO measurement_y2022m03 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'Date out of range.  Fix the measurement_insert_trigger() function!';
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER insert_measurement_trigger
    BEFORE INSERT ON measurement
    FOR EACH ROW EXECUTE FUNCTION measurement_insert_trigger();
   
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

-- tableoid |          time          | sensor_value | sensorID
------------+------------------------+-------+----------
--    19103 | 2022-01-03 07:00:00+00 |   2.9 |        2
--    19103 | 2022-01-06 07:00:00+00 |   3.5 |        1
--    19103 | 2022-01-15 07:00:00+00 |   6.2 |        3
--    19103 | 2022-01-23 07:00:00+00 |   3.2 |        1
--    19103 | 2022-01-28 07:00:00+00 |   5.2 |        2
--    19106 | 2022-02-04 07:00:00+00 |   4.1 |        3
--    19106 | 2022-02-09 07:00:00+00 |   5.2 |        1
--    19106 | 2022-02-13 07:00:00+00 |   2.6 |        2
--    19106 | 2022-02-24 07:00:00+00 |   1.7 |        2
--    19106 | 2022-02-28 07:00:00+00 |   6.1 |        1
--    19109 | 2022-03-06 07:00:00+00 |   5.2 |        3
--    19109 | 2022-03-08 07:00:00+00 |   2.3 |        2
--    19109 | 2022-03-12 07:00:00+00 |   1.6 |        1
--    19109 | 2022-03-27 06:00:00+00 |   2.5 |        3
--    19109 | 2022-03-29 06:00:00+00 |   5.3 |        2
--(15 rows)

SELECT 
    tablename, indexname
FROM
    pg_indexes
WHERE
    tablename LIKE 'measurement%';

--    tablename    |        indexname
-------------------+--------------------------
-- measurement_y2022m01 | measurement_y2022m01_time_idx
-- measurement_y2022m02 | measurement_y2022m02_time_idx
-- measurement_y2022m03 | measurement_y2022m03_time_idx
--(3 rows)


SET enable_partition_pruning = on;

EXPLAIN ANALYZE SELECT * FROM measurement WHERE time > '2022-03-01';

--                                                                                  QUERY PLAN
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Append  (cost=0.00..78.41 rows=1852 width=16) (actual time=0.007..0.008 rows=0 loops=1)
--    ->  Seq Scan on measurement measurement_1  (cost=0.00..0.00 rows=1 width=16) (actual time=0.002..0.002 rows=0 loops=1)
--          Filter: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m01_time_idx on measurement_y2022m01 measurement_2  (cost=0.15..23.05 rows=617 width=16) (actual time=0.002..0.002 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m02_time_idx on measurement_y2022m02 measurement_3  (cost=0.15..23.05 rows=617 width=16) (actual time=0.001..0.001 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m03_time_idx on measurement_y2022m03 measurement_4  (cost=0.15..23.05 rows=617 width=16) (actual time=0.001..0.001 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--  Planning Time: 0.299 ms
--  Execution Time: 0.027 ms
-- (11 rows)

SET enable_partition_pruning = off;

EXPLAIN ANALYZE SELECT * FROM measurement WHERE time > '2022-03-01';
--                                                                                  QUERY PLAN
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Append  (cost=0.00..78.41 rows=1852 width=16) (actual time=0.008..0.009 rows=0 loops=1)
--    ->  Seq Scan on measurement measurement_1  (cost=0.00..0.00 rows=1 width=16) (actual time=0.003..0.003 rows=0 loops=1)
--          Filter: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m01_time_idx on measurement_y2022m01 measurement_2  (cost=0.15..23.05 rows=617 width=16) (actual time=0.002..0.003 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m02_time_idx on measurement_y2022m02 measurement_3  (cost=0.15..23.05 rows=617 width=16) (actual time=0.001..0.001 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--    ->  Index Scan using measurement_y2022m03_time_idx on measurement_y2022m03 measurement_4  (cost=0.15..23.05 rows=617 width=16) (actual time=0.001..0.001 rows=0 loops=1)
--          Index Cond: ("time" > '2022-03-01 00:00:00+00'::timestamp with time zone)
--  Planning Time: 0.120 ms
--  Execution Time: 0.031 ms
-- (11 rows)