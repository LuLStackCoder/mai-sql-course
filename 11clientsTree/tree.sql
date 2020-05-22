--1st sol
SELECT DISTINCT client.id, client.name, client.client_groups, client_groups.name
FROM client
         JOIN client_groups ON client.client_groups = client_groups.id
UNION ALL
SELECT client.id, client.name, temp.parent, temp.parent_name
FROM client
         JOIN temp ON temp.id = client.client_groups
ORDER BY id;

--2nd sol
WITH RECURSIVE temp AS (
    SELECT g1.id, g1.name, g1.parent, g2.name parent_name
    FROM client_groups g1
             JOIN client_groups g2 ON g2.id = g1.parent
    UNION ALL
    SELECT g3.id, g3.name, temp.parent, g4.name
    FROM client_groups AS g3
             JOIN temp ON temp.id = g3.parent
             JOIN client_groups g4 ON g4.id = temp.parent)

