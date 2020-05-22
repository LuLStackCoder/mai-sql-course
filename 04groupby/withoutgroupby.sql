select distinct key1,
                key2,
                (select sum(data1)
                 from t x
                 where x.key1 = y.key1
                   and x.key2 = y.key2),
                (select min(data2)
                 from t x
                 where x.key1 = y.key1
                   and x.key2 = y.key2)
from t y;
