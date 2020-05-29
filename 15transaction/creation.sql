DROP TABLE IF EXISTS g;
DROP TABLE IF EXISTS test;
DROP TABLE IF EXISTS goods_groups CASCADE;
DROP TABLE IF EXISTS storage CASCADE;
DROP TABLE IF EXISTS recept CASCADE;
DROP TABLE IF EXISTS recgoods CASCADE;
DROP TABLE IF EXISTS region CASCADE;
DROP TABLE IF EXISTS income CASCADE;
DROP TABLE IF EXISTS incgoods CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS client_groups CASCADE;
DROP TABLE IF EXISTS cassa_income CASCADE;
DROP TABLE IF EXISTS city CASCADE;
DROP TABLE IF EXISTS goods CASCADE;
DROP TABLE IF EXISTS cassa_recept CASCADE;
DROP TABLE IF EXISTS bank_recept CASCADE;
DROP TABLE IF EXISTS bank_income CASCADE;
DROP TABLE IF EXISTS temp CASCADE;

drop SCHEMA if EXISTS purchase CASCADE;
drop SCHEMA if EXISTS remains CASCADE;
drop SCHEMA if EXISTS sale CASCADE;

CREATE TABLE region
(
	id   serial,
	name text,
	PRIMARY KEY (id)
);

CREATE TABLE city
(
	id     serial,
	name   text,
	region int REFERENCES region (id),
	PRIMARY KEY (id)
);

CREATE TABLE storage
(
	id   serial,
	name text,
	PRIMARY KEY (id)
);

CREATE TABLE client
(
	id      serial,
	name    text,
	address text,
	city    int REFERENCES city (id),
	PRIMARY KEY (id)
);

CREATE TABLE recept
(
	id      serial,
	ddate   date,
	ndoc    int,
	client  int REFERENCES client (id),
	storage int REFERENCES storage (id),
	PRIMARY KEY (id)
);

CREATE TABLE income
(
	id      serial,
	ddate   date,
	ndoc    int,
	client  int REFERENCES client (id),
	storage int REFERENCES storage (id),
	PRIMARY KEY (id)
);

CREATE TABLE goods_groups
(
	id     serial,
	name   text,
	parent int REFERENCES goods_groups (id),
	PRIMARY KEY (id)
);


CREATE TABLE goods
(
	id      serial,
	g_group int REFERENCES goods_groups (id),
	name    text,
	weight  decimal(18, 4),
	length  decimal(18, 4),
	height  decimal(18, 4),
	width   decimal(18, 4),
	PRIMARY KEY (id)
);

CREATE TABLE recgoods
(
	id     int REFERENCES recept (id),
	subid  int,
	goods  int REFERENCES goods (id),
	volume int,
	price  decimal(18, 4),
	PRIMARY KEY (id, subid)
);

CREATE TABLE incgoods
(
	id     int REFERENCES income (id),
	subid  int,
	goods  int REFERENCES goods (id),
	volume int,
	price  decimal(18, 4),
	PRIMARY KEY (id, subid)
);

CREATE TABLE cassa_income
(
	id     serial PRIMARY KEY,
	ddate  date,
	summ   int,
	client int REFERENCES client (id)
);

CREATE TABLE bank_income
(
	id     serial PRIMARY KEY,
	ddate  date,
	summ   int,
	client int REFERENCES client (id)
);

CREATE TABLE cassa_recept
(
	id     serial PRIMARY KEY,
	ddate  date,
	summ   int,
	client int REFERENCES client (id)
);

CREATE TABLE bank_recept
(
	id     serial PRIMARY KEY,
	ddate  date,
	summ   int,
	client int REFERENCES client (id)
);


INSERT INTO region(name)
SELECT ('Регион ' || t)::text
FROM generate_series(1, 5) t;

INSERT INTO city(name, region)
SELECT ('Город ' || t)::text,
       (SELECT id FROM region WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 100) t;


INSERT INTO client(name, address, city)
SELECT ('Клиент ' || t)::text,
       ('Address: Улица - ' || (SELECT * FROM generate_series(1, 227) WHERE t > 0 ORDER BY random() LIMIT 1))::text,
       (SELECT id FROM city WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 100) t;

INSERT INTO storage(name)
SELECT ('warehouse: ' || t)::text
FROM generate_series(1, 10) t;

INSERT INTO goods_groups(name, parent)
SELECT ('Group: ' || t)::text,
       (t)::int
FROM generate_series(1, 5) t;

INSERT INTO goods_groups(name, parent)
SELECT ('Subgroup: ' || t)::text,
       (SELECT id FROM goods_groups WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 5) t;

INSERT INTO goods(g_group, name, weight, length, height, width)
SELECT (SELECT id FROM goods_groups WHERE t > 0 ORDER BY random() LIMIT 1),
       ('Good: ' || t)::text,
       (SELECT * FROM generate_series(1, 10) WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(1, 14) WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(1, 5) WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(1, 4) WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 15) t;

CREATE OR REPLACE FUNCTION generate_dates(dt1 date,
                                          dt2 date,
                                          n int) RETURNS setof date AS
$$
SELECT $1 + i
FROM generate_series(0, $2 - $1, $3) i;
$$ LANGUAGE SQL IMMUTABLE;
INSERT INTO recept(ddate, ndoc, client, storage)
SELECT (SELECT * FROM generate_dates('2020-01-01', '2020-12-31', 5) WHERE t > 0 ORDER BY random() LIMIT 1) d,
       t,
       (SELECT client.id FROM client WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT storage.id FROM storage WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 1000) t
ORDER BY d;

INSERT INTO income(ddate, ndoc, client, storage)
SELECT (SELECT * FROM generate_dates('2019-01-01', '2019-12-31', 1) WHERE t > 0 ORDER BY random() LIMIT 1) d,
       t,
       (SELECT client.id FROM client WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT storage.id FROM storage WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 10000) t
ORDER BY d;


INSERT INTO incgoods(id, subid, goods, volume, price)
SELECT t,
       t,
       (SELECT goods.id FROM goods WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(500, 1500) WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(100, 300) WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 10000) t;

INSERT INTO recgoods(id, subid, goods, volume, price)
SELECT t,
       t,
       (SELECT goods.id FROM goods WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(100, 500) WHERE t > 0 ORDER BY random() LIMIT 1),
       (SELECT * FROM generate_series(350, 1500) WHERE t > 0 ORDER BY random() LIMIT 1)
FROM generate_series(1, 1000) t;


INSERT INTO bank_income(ddate, summ, client)
SELECT R.ddate, (R2.volume * R2.price) sum, R.client
FROM recept R
	     JOIN recgoods R2 ON R.id = R2.id
LIMIT 500;

INSERT INTO cassa_income(ddate, summ, client)
SELECT R.ddate, (R2.volume * R2.price) sum, R.client
FROM recept R
	     JOIN recgoods R2 ON R.id = R2.id
LIMIT 500 OFFSET 500;

INSERT INTO bank_recept(ddate, summ, client)
SELECT I.ddate, (I2.volume * I2.price) sum, I.client
FROM income I
	     JOIN incgoods I2 ON I.id = I2.id
LIMIT 5000;

INSERT INTO cassa_recept(ddate, summ, client)
SELECT I.ddate, (I2.volume * I2.price) sum, I.client
FROM income I
	     JOIN incgoods I2 ON I.id = I2.id
LIMIT 5000 OFFSET 5000;