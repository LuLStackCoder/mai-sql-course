DROP FUNCTION IF EXISTS moving_average(d1 date, d2 date);

CREATE OR REPLACE FUNCTION moving_average(d1 date, d2 date, alpha double precision)
    RETURNS table
            (
                city       int,
                goods      int,
                date       date,
                sum        int,
                prediction double precision
            )
AS
$$
DECLARE
    cursor CURSOR FOR SELECT C.city c, R2.goods g, R.ddate d, sum(R2.price * R2.volume) s
                      FROM recept R
                               JOIN recgoods R2 ON R.id = R2.id
                               JOIN client C ON R.client = C.id
                      WHERE R.ddate >= d1
                        AND R.ddate <= d2
                      GROUP BY c, g, d

    ;
    cnt             int := 0;
    prev_prediction double precision;
    prev_city       int := -1;
    prev_goods      int := -1;

--
    city            int;
    goods           int;
    date            date;
    sum             int;
BEGIN
    CREATE TEMP TABLE tmp
    (
        goods_id int,
        date     date,
        sum      int
    );
    CREATE TEMP TABLE to_return
    (
        city       int,
        goods      int,
        date       date,
        sum        int,
        prediction double precision
    );
    OPEN cursor;
    LOOP
        FETCH cursor INTO city, goods, date, sum;
        EXIT WHEN NOT found;

        IF city != prev_city OR goods != prev_goods THEN
            INSERT INTO to_return (city, goods, date, sum, prediction)
            VALUES (city, goods, date, sum, sum);
            prev_prediction = sum;
        ELSE
            INSERT INTO to_return (city, goods, date, sum, prediction)
            VALUES (city, goods, date, sum, sum * alpha + (1 - alpha) * prev_prediction);
            prev_prediction = sum * alpha + (1 - alpha) * prev_prediction;
        END IF;

        prev_goods = goods;
        prev_city = city;
        cnt := cnt + 1;
    END LOOP;

    CLOSE cursor;
    RETURN QUERY SELECT * FROM to_return;
    DROP TABLE to_return;
    DROP TABLE tmp;
END
$$ LANGUAGE plpgsql;

SELECT *
FROM moving_average('2020-02-01', '2020-12-31', 0.2);
