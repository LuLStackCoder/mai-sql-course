DROP TABLE temp;
CREATE TABLE temp
(
    date       date,
    warehouse  int,
    sum        int,
    volume     int,
    uniq_goods int
);

-- Inserting
INSERT INTO temp(date, warehouse, sum, volume, uniq_goods)
SELECT income.ddate,
       income.storage,
       sum(incgoods.volume * incgoods.price)                            AS ssum,
       sum(goods.height * goods.width * goods.length * incgoods.volume) AS volume,
       count(DISTINCT incgoods.goods)
FROM income
         JOIN incgoods ON income.id = incgoods.id
         JOIN goods ON goods.id = incgoods.goods
GROUP BY income.ddate, income.storage;

-- Updating
ALTER TABLE storage
    ADD COLUMN active int;

WITH warehourse_sales AS (
    SELECT recept.storage, sum(recgoods.volume * recgoods.price) AS ssum
    FROM recept
             JOIN recgoods ON recept.id = recgoods.id
    WHERE recept.ddate > date_trunc('month', current_date - INTERVAL '1' MONTH)
    GROUP BY recept.storage
    HAVING sum(recgoods.volume * recgoods.price) > 10000)

UPDATE storage
SET active = 1
WHERE id IN (SELECT storage FROM warehourse_sales);

SELECT *
FROM storage;

-- Deleting
DELETE
FROM goods
WHERE id NOT IN (SELECT goods FROM recgoods)
  AND id NOT IN (SELECT goods FROM incgoods)
RETURNING id;

