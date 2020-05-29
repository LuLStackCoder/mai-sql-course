DROP SCHEMA IF EXISTS sale CASCADE;
CREATE SCHEMA sale;
SET search_path = "sale";

DROP TABLE IF EXISTS date CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS storage CASCADE;
DROP TABLE IF EXISTS goods CASCADE;
DROP TABLE IF EXISTS sale CASCADE;


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
CREATE TABLE sale
(
	id         serial PRIMARY KEY,
	date_id    int REFERENCES date (id),
	client_id  int REFERENCES client (id),
	goods_id   int REFERENCES goods (id),
	storage_id int REFERENCES storage (id),
	date       date,

	sum        int,
	count      int,
	volume     int,
	weight     int,
	cost_price int,
	sell_price int
);

INSERT INTO date (date)
SELECT DISTINCT public.recept.ddate date
FROM public.recept
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


INSERT INTO sale (date_id, client_id, goods_id, storage_id, date, sum, count, volume, weight, cost_price, sell_price)
SELECT D.id       date_id,
       R1.client  client_id,
       R2.goods   goods_id,
       R1.storage storage_id,
       R1.ddate,

       sum(R2.volume * R2.price),
       R2.volume,
       R2.volume * G.item_weight,
       sum(G.item_weight),
       (SELECT P.purchase_price FROM purchase.purchase P WHERE p.date_id <= D.id AND p.goods_id = R2.goods LIMIT 1),
       R2.price
FROM public.recept R1
	     JOIN public.recgoods R2 ON R1.id = R2.id
	     JOIN goods G ON G.id = R2.goods
	     JOIN date D ON D.date = R1.ddate
GROUP BY D.id, R1.client, R2.goods, R1.storage, R1.ddate, R2.volume, R2.volume * G.item_weight,
         (SELECT P.purchase_price FROM purchase.purchase P WHERE p.date_id <= D.id AND p.goods_id = R2.goods LIMIT 1),
         R2.price;

