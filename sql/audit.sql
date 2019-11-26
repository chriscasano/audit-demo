SET CLUSTER SETTING cluster.organization = '';
SET CLUSTER SETTING enterprise.license = '';
SET CLUSTER SETTING kv.rangefeed.enabled=true;

drop database if exists cis cascade;
create database cis;

use cis;

create table customers
(
  customer_id UUID,
  name string,
  street string,
  city string,
  state string(2),
  zip int,
  people int,
  revenue decimal(10,2),
  PRIMARY KEY(customer_id)
);

create table orders
(
  order_id UUID,
  name string,
  PRIMARY KEY(order_id)
);

CREATE CHANGEFEED FOR TABLE customers INTO 'kafka://broker:29092?topic_prefix=cis_json_' WITH updated, key_in_value, format = json, confluent_schema_registry = 'http://schema-registry:8081';
CREATE CHANGEFEED FOR TABLE orders INTO 'kafka://broker:29092?topic_prefix=cis_json_' WITH updated, key_in_value, format = json, confluent_schema_registry = 'http://schema-registry:8081';

SHOW JOBS;

create table audit
(
  tbl string not null, --kafka.topic
  pk string not null, --kafka.key
  ts timestamp not null, --updated
  ts2 timestamp,
  ts3 timestamp default now(),
  action string, --after
  new string, --after
  prev string,
  PRIMARY KEY (tbl, pk, ts)
);

insert into customers values
(gen_random_uuid(), 'Chris', '1 Happpy St', 'Merrick', 'NY', '11566', 1, 1.380),
(gen_random_uuid(), 'Oscar', '2 Sullen St', 'Middletown', 'NY', '22222', 55, 909.7),
(gen_random_uuid(), 'Carli', '3 Peezy St', 'Ellenville', 'NY', '34567', 900, 100),
(gen_random_uuid(), 'Jenny', '55 Papa St', 'San Diego', 'CA', '98765', 1000, 0.98),
(gen_random_uuid(), 'Harry', '100 Street St', 'El Paso', 'TX', '56738', 63, 0)
;

insert into orders values
(gen_random_uuid(), 'Chris'),
(gen_random_uuid(), 'Oscar'),
(gen_random_uuid(), 'Carli'),
(gen_random_uuid(), 'Jenny'),
(gen_random_uuid(), 'Harry')
;


update customers set
street = '9 Madison Ave'
where name = 'Chris';
;

delete from customers where name = 'Harry';

drop user if exists maxroach;
create user maxroach;
grant admin to maxroach;
grant ALL on cis.* to maxroach;
