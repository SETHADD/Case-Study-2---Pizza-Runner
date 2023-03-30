
/*update the column extra_1 with null  */
UPDATE dbo.customer_orders_
SET extra_2= null
WHERE extra_2 = 1


/*create a new table cancellations from the runner_orders table */
select 
order_id,
runner_id, 
cancellation
into cancellations
from dbo.runner_orders
where cancellation is not null


/*create a new table from the customer_orders table*/
 select 
 order_id,
 customer_id,
 pizza_id,
LEFT(exclusions,1) exclusion_1,
RIGHT(exclusions,1) exclusion_2,
LEFT(extras,1) extra_1,
RIGHT(extras,1)extra_2,
substring( CAST(order_time as varchar),CHARINDEX(' ',  CAST(order_time as varchar), 9 ),LEN( CAST(order_time as varchar))) order_time,
substring(CAST(order_time as varchar),1,CHARINDEX(' ', cast(order_time as varchar),8)) date_ordered
into customer_orders_
from dbo.customer_orders

/*create a new table */
create table runner_orders1
as
select 
order_id,
runner_id,
substring( CAST(pickup_time as varchar),CHARINDEX(' ',  CAST(pickup_time as varchar), 9 ),LEN( CAST(pickup_time as varchar))) order_time,
LEFT(cast(pickup_time as varchar),CHARINDEX(' ', cast(pickup_time as varchar),8)) date_1,
cast(LEFT(duration,2) as int) duration_minutes,
cast(REPLACE(distance,'km','') as decimal) distance_km
from dbo.runner_orders


alter table dbo.pizza_recipes1
add foreign key(pizza_id) references dbo.pizza_recipes(pizza_id)

/*this is a code to drop the constraint*/
alter table dbo.cancellations
drop constraint  FK__cancellat__order__151B244E

/*this code is use to completely delete a column */
alter table dbo.pizza_recipes1
drop column cancellation



/*the following code is use to split the row with by the delimiter ',' and add it to a new table called pizza_recipes1 */
select pizza_id , cast(trim(value) as int) as topping
into pizza_recipes1
from dbo.pizza_recipes
cross apply
string_split(cast(toppings as varchar),',')
order by topping asc

/*This is use to add a primary key to the table*/
alter table dbo.runner_orders1
add primary key(order_id)

/*This is use to add a constraints to the table*/
alter table dbo.pizza_toppings
alter column topping_id int not null

/*this code adds a foreign key to the table*/
alter table dbo.runner_orders1
add FOREIGN KEY(runner_id) REFERENCES dbo.runners(runner_id)

alter table dbo.customer_orders_ 
add foreign key(order_id) references dbo.runner_ratings(order_id)

/*delete the duplicate rows in the table*/
delete tab6
from  ( 
select *,
row_num= ROW_NUMBER() over(partition by order_id,customer_id,pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,order_time,date_ordered order by (select null)) 
from dbo.customer_orders_
) tab6
where row_num > 1


/*create new table customer_orders_*/
INSERT INTO customer_orders_
 select  distinct *
 from dbo.customer_orders_
 group by order_id,customer_id,pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,order_time,date_ordered
 having COUNT(*) > 1


alter table dbo.pizza_toppings
alter column topping_name varchar(25)