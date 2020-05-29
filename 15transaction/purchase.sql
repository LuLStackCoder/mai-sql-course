DROP SCHEMA IF EXISTS purchase CASCADE;
CREATE SCHEMA purchase;
SET search_path = "purchase";

DROP TABLE IF EXISTS date CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS storage CASCADE;
DROP TABLE IF EXISTS goods CASCADE;
DROP TABLE IF EXISTS purchase CASCADE;

CREATE TABLE IF NOT EXISTS date
(
	id   serial PRIMARY KEY,
	date date
);
CREATE TABLE IF NOT EXISTS client
(
	id      serial PRIMARY KEY,
	city    int,
	name    text,
	address text
);
CREATE TABLE IF NOT EXISTS storage
(
	id   serial PRIMARY KEY,
	name text
);
CREATE TABLE IF NOT EXISTS goods
(
	id          serial PRIMARY KEY,
	goods_group int,
	item_weight int,
	item_volume int,
	name        text
);
CREATE TABLE purchase
(
	id             serial PRIMARY KEY,
	date_id        int REFERENCES date (id),
	client_id      int REFERENCES client (id),
	goods_id       int REFERENCES goods (id),
	storage_id     int REFERENCES storage (id),
	date           date,
	purchase_price int,

	count          int,
	sum            int,
	volume         int,
	weight         int
);

INSERT INTO date (date)
SELECT DISTINCT public.income.ddate date
FROM public.income
ORDER BY date;

INSERT INTO client (city, name, address)
SELECT C.city, C.name, C.address
FROM public.client C;

INSERT INTO goods (goods_group, item_weight, item_volume, name)
SELECT G.g_group, G.weight, (G.weight * G.height * G.length), G.name
FROM public.goods G;

INSERT INTO storage (name)
SELECT S.name
FROM public.storage S;

INSERT INTO purchase (date_id, client_id, goods_id, storage_id, date, purchase_price, sum, count, volume, weight)
SELECT D.id,
       I1.client,
       I2.goods,
       I1.storage,
       I1.ddate,
       I2.price,

       sum(I2.volume * I2.price),
       I2.volume,
       I2.volume * G.item_weight,
       sum(G.item_weight)
FROM public.income I1
	     JOIN public.incgoods I2 ON I1.id = I2.id
	     JOIN goods G ON G.id = I2.goods
	     JOIN date D ON D.date = I1.ddate
GROUP BY D.id, I1.client, I2.goods, I1.storage, I1.ddate, I2.price, I2.volume, I2.volume * G.item_weight;


