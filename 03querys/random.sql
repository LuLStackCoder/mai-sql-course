SELECT *
FROM (SELECT city.name                                    city,
             region.name                                  region,
             income.ndoc                                  document_number,
             goods_groups.name                            g_group,
             goods.name                                   goods,
             (goods.weight * goods.length * goods.height) volume
      FROM region
               JOIN city ON region.id = city.region
               JOIN client ON city.id = client.city
               JOIN income ON client.id = income.client
               JOIN incgoods ON income.id = incgoods.id
               JOIN goods ON incgoods.goods = goods.id
               JOIN goods_groups ON goods.g_group = goods_groups.id
      WHERE income.ddate > '01-04-2020'
        AND volume > 10) as foo
ORDER BY random()
LIMIT 10
