DROP TABLE IF EXISTS measurement;
CREATE TABLE measurement (
    time TIMESTAMPTZ NOT NULL,
    sensorID INT NULL,
    sensor_value REAL NULL
);

SELECT create_hypertable('measurement','time');

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
--     19204 | 2022-01-03 00:00:00+00 |        2 |          2.9
--     19210 | 2022-01-06 00:00:00+00 |        1 |          3.5
--     19216 | 2022-01-15 00:00:00+00 |        3 |          6.2
--     19222 | 2022-01-23 00:00:00+00 |        1 |          3.2
--     19228 | 2022-01-28 00:00:00+00 |        2 |          5.2
--     19234 | 2022-02-04 00:00:00+00 |        3 |          4.1
--     19234 | 2022-02-09 00:00:00+00 |        1 |          5.2
--     19240 | 2022-02-13 00:00:00+00 |        2 |          2.6
--     19246 | 2022-02-24 00:00:00+00 |        2 |          1.7
--     19246 | 2022-02-28 00:00:00+00 |        1 |          6.1
--     19252 | 2022-03-06 00:00:00+00 |        3 |          5.2
--     19252 | 2022-03-08 00:00:00+00 |        2 |          2.3

INSERT INTO measurement (time, sensorID, sensor_value) SELECT 
    (timestamptz '2022-01-01' + random() * (timestamptz '2022-01-01' - timestamptz '2022-12-30')), 
    generate_series(0,10000000),
    random()*2-random();


CREATE INDEX ON measurement (sensor_value);

CREATE MATERIALIZED VIEW measurement_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', "time") AS day,
    avg(sensor_value) AS avg,
    count(sensor_value) AS count
FROM measurement
GROUP BY day;

SELECT day AS time, avg FROM measurement_daily;

CREATE MATERIALIZED VIEW measurement_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', "time") AS hour,
    avg(sensor_value) as avg,
    count(sensor_value) as count
FROM measurement
GROUP BY hour;


ALTER TABLE measurement SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC',
  timescaledb.compress_segmentby = 'sensorID'
);

SELECT add_compression_policy('measurement', INTERVAL '2 weeks');

SELECT compress_chunk(i, if_not_compressed=>true)
  FROM show_chunks('measurement', older_than => INTERVAL ' 2 weeks') i;


SELECT add_retention_policy('measurement', INTERVAL '5 years');

