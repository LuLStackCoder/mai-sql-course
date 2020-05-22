WITH RECURSIVE temp AS (
    SELECT g1.id, g1.name, g1.parent, g2.name parent_name
    FROM goods_groups AS g1
             JOIN goods_groups AS g2 ON g2.id = g1.parent
    UNION ALL
    SELECT goods_groups.id, goods_groups.name, temp.parent, gp.name
    FROM goods_groups AS goods_groups
             JOIN temp ON temp.id = goods_groups.parent
             JOIN goods_groups AS gp ON gp.id = temp.parent)

SELECT *
FROM temp;
