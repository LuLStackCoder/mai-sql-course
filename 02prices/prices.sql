create table partner
(
    id   SERIAL,
    name text,
    PRIMARY KEY (id)
);
create table goods_group
(
    id   SERIAL,
    name text,
    PRIMARY KEY (id)
);
create table good
(
    id             SERIAL,
    name           text,
    id_goods_group int REFERENCES goods_group (id),
    PRIMARY KEY (id)
);
create table price_list
(
    id   SERIAL,
    name text,
    PRIMARY KEY (id)
);
create table price_partner_list
(
    id            SERIAL,
    id_price_list int REFERENCES price_list (id),
    id_good       int REFERENCES good (id),
    price         decimal(18, 4),
    ddate         date,
    PRIMARY KEY (id)
);
create table group_part
(
    id   serial,
    name text,
    PRIMARY KEY (id)
);
create table goods_part_group
(
    id             serial,
    id_group_part  int REFERENCES group_part (id),
    id_goods_group int REFERENCES goods_group (id),
    PRIMARY KEY (id)
);
create table price_goods_part_group
(
    id            serial,
    id_price_list int REFERENCES price_list (id),
    id_group_part int REFERENCES group_part (id),
    id_partner    int REFERENCES partner (id),
    PRIMARY KEY (id)
);

-- Inserting pseudo-random values
insert into partner(name)
select ('Partner ' || t)::text
from generate_series(1, 20) t;

insert into goods_group(name)
select ('Goods group ' || t)::text
from generate_series(1, 10) t;

insert into good(name, id_goods_group)
select ('Good ' || t)::text,
       (select id
        from goods_group
        where t > 0
        order by random()
        limit 1)
from generate_series(1, 50) t;

insert into price_list(name)
select ('Price ' || t)::text
from generate_series(1, 20) t;

insert into price_partner_list(id_price_list, id_good, price, ddate)
select (select id
        from price_list
        where t > 0
        order by random()
        limit 1),
       (select id
        from good
        where t > 0
        order by random()
        limit 1),
       t * 2.5,
       '2020-03-01'::date + t
from generate_series(1, 30) t;

insert into group_part(name)
select ('Partner goods group ' || t)::text
from generate_series(1, 10) t;

insert into goods_part_group(id_group_part, id_goods_group)
select (select id
        from group_part
        where t > 0
        order by random()
        limit 1),
       (select id
        from goods_group
        where t > 0
        order by random()
        limit 1)
from generate_series(1, 30) t;

insert into price_goods_part_group(id_price_list, id_group_part, id_partner)
select (select id
        from price_list
        where t > 0
        order by random()
        limit 1),
       (select id
        from group_part
        where t > 0
        order by random()
        limit 1),
       (select id
        from partner
        where t > 0
        order by random()
        limit 1)
from generate_series(1, 30) t;

-- Prices for a one partner on date
with product as (select prl.id_good,
                        g.name,
                        g.id_goods_group,
                        ggp.id_group_part,
                        prl.price,
                        prl.ddate,
                        prl.id_price_list
                 from price_partner_list prl
                          join good g on g.id = prl.id_good
                          join goods_part_group ggp on ggp.id_goods_group = g.id_goods_group)
select distinct pr.name, pr.price
from price_goods_part_group pgg
         join product pr on pr.id_price_list = pgg.id_price_list and pgg.id_group_part = pr.id_group_part
where pgg.id_partner = 4
  and pr.ddate = '2020-03-05';

-- Products with different prices inside partner
with temp as (SELECT tab.name, tab.id_good, tab.ddate, tab.id_partner, count(*)
              from (
                       select distinct g.name, pprl.id_good, pprl.ddate, pgg.id_partner, pprl.id_price_list
                       from price_partner_list pprl
                                join good g on g.id = pprl.id_good
                                join goods_part_group ggp on ggp.id_goods_group = g.id_goods_group
                                join price_goods_part_group pgg
                                     on pprl.id_price_list = pgg.id_price_list and
                                        pgg.id_group_part = ggp.id_group_part) TAB
              group BY tab.name, tab.id_good, tab.ddate, tab.id_partner
              having count(*) > 1)
select g.name, pprl.id_good, pprl.ddate, pgg.id_partner, string_agg(pprl.id_price_list::text, ',')
from price_partner_list pprl
         join good g on g.id = pprl.id_good
         join goods_part_group ggp on ggp.id_goods_group = g.id_goods_group
         join price_goods_part_group pgg
              on pprl.id_price_list = pgg.id_price_list and pgg.id_group_part = ggp.id_group_part
where pprl.id_good in (select id_good from temp)
  and pprl.ddate in (select ddate from temp)
  and pgg.id_partner in (select id_partner from temp)
group by g.name, pprl.id_good, pprl.ddate, pgg.id_partner;
