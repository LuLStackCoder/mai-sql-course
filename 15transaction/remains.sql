DROP SCHEMA IF EXISTS remains CASCADE;
CREATE SCHEMA remains;
SET search_path = "remains";

DROP TABLE IF EXISTS date CASCADE;
DROP TABLE IF EXISTS storage CASCADE;
DROP TABLE IF EXISTS goods CASCADE;
DROP TABLE IF EXISTS remains CASCADE;


CREATE TABLE IF NOT EXISTS date
(
	id   serial PRIMARY KEY,
	date date
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

CREATE TABLE remains
(
	id         serial PRIMARY KEY,
	date_id    int REFERENCES date (id),
	goods_id   int REFERENCES goods (id),
	storage_id int REFERENCES storage (id),
	date       date,

	sum        int,
	count      int,
	volume     int,
	weight     int
);

INSERT INTO date (date)
SELECT DISTINCT TEMP.date
FROM (
	     SELECT public.income.ddate date
	     FROM public.income
	     UNION
	     SELECT public.recept.ddate date
	     FROM public.recept
     ) temp
ORDER BY TEMP.date;

INSERT INTO storage (name)
SELECT S.name
FROM public.storage S;

INSERT INTO goods (goods_group, item_weight, item_volume, name)
SELECT G.g_group, G.weight, (G.weight * G.height * G.length), G.name
FROM public.goods G;

INSERT INTO remains(date_id, goods_id, storage_id, date, sum, count, volume, weight)
SELECT TEMP.date_id,
       TEMP.goods_id,
       TEMP.storage_id,
       TEMP.date,
       (coalesce((SELECT sum(P.count)
                  FROM purchase.purchase P
                  WHERE P.date_id <= TEMP.date_id
	                AND P.goods_id = TEMP.goods_id
	                AND P.storage_id = TEMP.storage_id), 0) - coalesce((SELECT sum(S.count)
                                                                        FROM sale.sale S
                                                                        WHERE S.date_id <= TEMP.date_id
	                                                                      AND S.goods_id = TEMP.goods_id
	                                                                      AND S.storage_id = TEMP.storage_id), 0)) *
       (SELECT P.purchase_price
        FROM purchase.purchase P
        WHERE P.date_id <= TEMP.date_id
	      AND P.goods_id = TEMP.goods_id
	      AND P.storage_id = TEMP.storage_id
        ORDER BY p.date_id DESC
        LIMIT 1)                                                                                                 sum,
       coalesce((SELECT sum(P.count)
                 FROM purchase.purchase P
                 WHERE P.date_id <= TEMP.date_id
	               AND P.goods_id = TEMP.goods_id
	               AND P.storage_id = TEMP.storage_id), 0) - coalesce((SELECT sum(S.count)
                                                                       FROM sale.sale S
                                                                       WHERE S.date_id <= TEMP.date_id
	                                                                     AND S.goods_id = TEMP.goods_id
	                                                                     AND S.storage_id = TEMP.storage_id), 0) count,
       (coalesce((SELECT sum(P.count)
                  FROM purchase.purchase P
                  WHERE P.date_id <= TEMP.date_id
	                AND P.goods_id = TEMP.goods_id
	                AND P.storage_id = TEMP.storage_id), 0) - coalesce((SELECT sum(S.count)
                                                                        FROM sale.sale S
                                                                        WHERE S.date_id <= TEMP.date_id
	                                                                      AND S.goods_id = TEMP.goods_id
	                                                                      AND S.storage_id = TEMP.storage_id), 0)) *
       (SELECT P.weight
        FROM purchase.purchase P
        WHERE P.date_id <= TEMP.date_id
	      AND P.goods_id = TEMP.goods_id
	      AND P.storage_id = TEMP.storage_id
        ORDER BY TEMP.date_id DESC
        LIMIT 1)
                                                                                                                 volume,
       (SELECT P.weight
        FROM purchase.purchase P
        WHERE P.date_id <= TEMP.date_id
	      AND P.goods_id = TEMP.goods_id
	      AND P.storage_id = TEMP.storage_id
        ORDER BY TEMP.date_id DESC
        LIMIT 1)                                                                                                 weight
FROM (
	     SELECT S.date_id, S.goods_id, S.storage_id, S.sum, S.count, S.date
	     FROM sale.sale S
	     UNION
	     SELECT P.date_id, P.goods_id, P.storage_id, P.sum, P.count, P.date
	     FROM purchase.purchase P
     ) temp;


SELECT *
FROM remains
LIMIT 3;