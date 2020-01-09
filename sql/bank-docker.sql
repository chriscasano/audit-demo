SET CLUSTER SETTING cluster.organization = '';
SET CLUSTER SETTING enterprise.license = '';
SET CLUSTER SETTING kv.rangefeed.enabled=true;

drop database if exists cis cascade;
create database cis;
use cis;

create table audit
(
  tbl string not null, --kafka.topic
  pk string not null, --kafka.key
  ts string not null, --updated
  ts1 timestamp,
  ts2 timestamp,
  ts3 timestamp default now(),
  action string, --after
  new string, --after
  prev string,
  PRIMARY KEY (tbl, pk, ts)
);

CREATE TABLE bank2 (
    id INT8 NOT NULL,
    balance INT8 NULL,
    payload STRING NULL,
    PRIMARY KEY (id ASC)
);

use bank;

CREATE CHANGEFEED FOR TABLE bank INTO 'kafka://broker:29092?topic_prefix=bank_json_' WITH updated, key_in_value, format = json, confluent_schema_registry = 'http://schema-registry:8081';
