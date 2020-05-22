SELECT client.address, recept.ddate, recept.ndoc, storage.name, goods.name, goods.weight, cassa_income.summ
FROM cassa_income
         INNER JOIN client ON (cassa_income.client = client.id)
         INNER JOIN city ON (client.city = city.id)
         INNER JOIN recept ON (client.id = recept.client)
         INNER JOIN storage ON (recept.storage = storage.id)
         INNER JOIN recgoods ON (recept.id = recgoods.id)
         INNER JOIN goods ON (recgoods.goods = goods.id)
WHERE recept.ddate > '01-02-2020'
  AND recept.ddate < '29-02-2020'
  AND city.name = 'Moscow'
  AND date_part('year', cassa_income.ddate) = '2019'
