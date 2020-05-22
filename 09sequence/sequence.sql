CREATE OR REPLACE FUNCTION getSequence(n INT)
    RETURNS TABLE
            (
                num INT
            )
AS
$$
DECLARE
    i INT;
BEGIN
    CREATE temp TABLE temp
    (
        num INT
    );
    FOR i IN 1..n
        LOOP
            INSERT INTO temp VALUES (i);
        END LOOP;
    RETURN query
        SELECT * FROM temp;
    DROP TABLE temp;
END;
$$ LANGUAGE plpgsql;

SELECT num
FROM getSequence(10);
