create database prices;
create table price (
          modify_id serial primary key,
          product_id int,
        datev date default NULL,
    price int
);

insert into price(product_id, datev, price)
values (1, '2013-06-01', 100);
insert into price(product_id, datev, price)
values (2, '2013-06-01', 200);
insert into price(product_id, datev, price)
values (3, '2013-06-01', 50);
insert into price(product_id, datev, price)
values (1, '2013-06-10', 200);
insert into price(product_id, datev, price)
values (2, '2013-06-12', 300);
insert into price(product_id, datev, price)
values (3, '2013-06-13', 500);
insert into price(product_id, datev, price)
values (1, '2013-06-15', 250);
select price from price where datev >= (select max(datev) from price) and product_id = 1
