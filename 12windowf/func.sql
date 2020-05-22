SELECT ndoc,
       ddate,
       goods.name,
       client.name,
       recgoods.volume * recgoods.price                                    AS ssum,
       AVG(recgoods.volume * recgoods.price)
       OVER (PARTITION BY goods ORDER BY extract(MONTH FROM ddate))        AS average,
       SUM(recgoods.volume * recgoods.price)
       OVER (PARTITION BY ddate ORDER BY recgoods.volume * recgoods.price) AS day_sum
FROM recept
         JOIN recgoods ON recept.id = recgoods.id
         JOIN client ON recept.client = client.id
         JOIN goods ON recgoods.goods = goods.id

