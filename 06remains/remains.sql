WITH date_t AS
         (
             SELECT '2020-03-01'::date + day AS ddate
             FROM generate_series(0, 13) day
         )
SELECT incs.ddate,
       incs.storage,
       incs.goods,
       COALESCE(incs.inc_vol, 0) - COALESCE(recs.rec_vol, 0)
FROM (
         SELECT date_t.ddate,
                inc.storage,
                incgoods.goods,
                SUM(incgoods.volume) inc_vol
         FROM income inc
                  JOIN
              incgoods
              ON incgoods.id = inc.id
                  JOIN
              date_t
              ON date_t.ddate >= inc.ddate
         GROUP BY date_t.ddate,
                  inc.storage,
                  incgoods.goods
     )
         AS incs
         FULL OUTER JOIN
     (
         SELECT date_t.ddate,
                rec.storage,
                recgoods.goods,
                SUM(recgoods.volume) rec_vol
         FROM recept rec
                  JOIN
              recgoods
              ON recgoods.id = rec.id
                  JOIN
              date_t
              ON date_t.ddate >= rec.ddate
         GROUP BY date_t.ddate,
                  rec.storage,
                  recgoods.goods
     )
         AS recs
     ON recs.ddate = incs.ddate
         AND recs.storage = incs.storage
         AND recs.goods = incs.goods
ORDER BY incs.ddate,
         incs.storage

