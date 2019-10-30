# Need enterprise license for CDC
SET CLUSTER SETTING cluster.organization = '';
SET CLUSTER SETTING enterprise.license = '';
SET CLUSTER SETTING kv.rangefeed.enabled=true;

create database cis;

create user maxroach with password maxroach;

grant admin to maxroach;

use cis;

create table customers
(
  id UUID,
  name string,
  street string,
  city string,
  state string(2),
  zip int,
  people int,
  revenue decimal,
  PRIMARY KEY(id)
);

CREATE CHANGEFEED FOR TABLE customers INTO 'kafka://broker:9092?topic_prefix=cis_';

SHOW JOBS;

create table customers_audit
(
  ts timestamp not null,
  attribute string not null,
  previous string,
  new string,
  action string,
  PRIMARY KEY (ts, attribute)
);

insert into customers values
(gen_random_uuid(), 'Chris', '1 Happpy St', 'Merrick', 'NY', '11566', 1, 1.380),
(gen_random_uuid(), 'Oscar', '2 Sullen St', 'Middletown', 'NY', '22222', 55, 909.7),
(gen_random_uuid(), 'Carli', '3 Peezy St', 'Ellenville', 'NY', '34567', 900, 100),
(gen_random_uuid(), 'Jenny', '55 Papa St', 'San Diego', 'CA', '98765', 1000, 0.98),
(gen_random_uuid(), 'Harry', '100 Street St', 'El Paso', 'TX', '56738', 63, 0)
;

update customers set
street = '9 Madison Ave'
where name = 'Chris';
;
