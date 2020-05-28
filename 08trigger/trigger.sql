create or replace function Updated() returns trigger as
$$
declare
    recept_storage integer;
    recept_date    date;
    income_date    date;
    item           record;
    dif_value      int;

begin
    select recept.storage,
           recept.ddate
    into recept_storage, recept_date
    from recept
    where recept.id = new.id;
    if (old.volume < new.volume) then

        drop table if exists rms;
        create temp table rms
        (
            id     int,
            subid  int,
            goods  int,
            ddate  date, -- прихода
            volume int
        );

        insert into rms(id, subid, goods, ddate, volume)
        select r.id,
               r.subid,
               r.goods,
               r.ddate,
               r.volume
        from remains r
        where r.goods = new.goods
          and r.storage = recept_storage
          and r.ddate < recept_date
        order by ddate;

        dif_value = new.volume - old.volume;
        for item in select * from rms
        loop
            if (dif_value > item.volume) then
                if (select exists(select 1 from irlink where i_id = item.id and r_id = item.id)) then
                    update irlink
                    set irlink.volume = irlink.volume + item.volume
                    where irlink.r_id = new.id
                    and irlink.r_id;
                else
                        insert into
                            irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                        values
                            (item.id, item.subid, new.id, new.subid, new.goods, item.volume);
                end if;
                delete from remains where remains.id = item.id;
                dif_value = dif_value - item.volume;
            else
                if (select exists(select 1 from irlink where i_id = item.id and r_id = new.id)) then
                    update irlink
                    set volume = volume + dif_value
                    where r_id = new.id
                    and i_id = item.id;
                else
                    insert into
                        irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                    values
                        (item.id, item.subid, new.id, new.subid, new.goods, dif_value);
                end if;

                update remains set volume = volume - dif_value where id = item.id;
                dif_value = 0;
            end if;
        exit when dif_value = 0;
        end loop;
    else
        drop table if exists incg;
        create temp table incg(
            id integer,
            i_id integer,
            i_subid integer,
            goods integer,
            volume integer
        );

        insert into incg(id, i_id, i_subid, goods)
        select id, i_id, i_subid, goods
        from irlink
        where irlink.r_id = new.id
        and irlink.goods = new.goods;

        dif_value = old.volume - new.volume;
        for item in select * from incg
        loop
            if (dif_value > item.volume) then
                  if (select exists(select 1 from remains where id = item.i_id and remains.subid = item.i_subid)) then
                    update remains
                    set remains.volume = remains.volume + item.volume
                    where id = item.i_id
                    and subid = item.i_subid;
                else
                        select ddate into income_date
                        from income
                        where id = item.id;

                        insert into
                            remains(id, subid, goods, storage, ddate, volume)
                        values
                            (item.i_id, item.i_subid, item.goods,recept_storage, income_date, item.volume);
                end if;
                delete from irlink where id = item.id;
                dif_value = dif_value - item.volume;
            else
                if (select exists(select 1 from remains where id = item.i_id and subid = item.i_subid)) then
                    update remains
                    set volume = volume + dif_value
                    where id = item.i_id
                    and subid = item.i_subid;

                    update irlink set volume = volume - dif_value
                    where id = item.id;

                    dif_value = 0;
                else
                        select ddate into income_date
                        from income
                        where id = item.id;

                        insert into
                            remains(id, subid, goods, storage, ddate, volume)
                        values
                            (item.i_id, item.i_subid, item.goods,recept_storage, income_date, dif_value);

                        update irlink set volume = volume - dif_value
                        where id = item.id;
                end if;
                dif_value = 0;
            end if;
        end loop;
    end if;

    return new;
end
$$ language plpgsql;

create or replace function Updating() returns trigger as
$$
declare
    recept_storage integer;
    recept_date    date;
    sum            integer;
begin
    select recept.storage,
           recept.ddate
    into recept_storage, recept_date
    from recept
    where recept.id = new.id;

    sum = (
        select sum(volume)
        from remains
        where remains.goods = new.goods
          and remains.ddate < recept_date
          and remains.storage = recept_storage
    ); --текущий остаток на складе

    if (old.id != new.id or old.subid != new.subid) then
        raise exception 'Only volume can be updated. All other values from recgoods are fixed';
    end if;

    if (new.volume > old.volume and new.volume - old.volume > sum) then
        raise exception 'There are not enough items in storage to satisfy requested volume';
    end if;

    return new;
end
$$ language plpgsql;

drop trigger if exists onUpdated on recgoods;
drop trigger if exists onUpdating on recgoods;

create trigger onUpdated
    after update
    on recgoods
    for each row
execute procedure Updated();

create trigger onUpdating
    before update
    on recgoods
    for each row
execute procedure Updating();