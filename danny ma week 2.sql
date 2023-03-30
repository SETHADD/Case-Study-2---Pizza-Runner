/* How many pizzas were ordered*/
select COUNT(*)
from dbo.customer_orders_ c

/* How many unique customer orders were made? */
select count( distinct order_id)
from dbo.customer_orders_

/*How many successful orders were delivered by each runner?*/
select r.runner_id,count(*) deliveries
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.runner_id

/*How many of each type of pizza was delivered?*/
select cu.pizza_id,count(*) delivered
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by cu.pizza_id

/* How many Vegetarian and Meatlovers were ordered by each customer?*/
select pizza_name, count(*)
from dbo.customer_orders_ c
left join dbo.pizza_names p
on c.pizza_id = p.pizza_id
group by pizza_name

/*What was the maximum number of pizzas delivered in a single order?*/
select top 2 r.order_id, delivered = COUNT(*) 
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.order_id
order by  delivered desc

/*For each customer, how many delivered pizzas had at least 1 change and how many had no changes?*/

/*at least one change*/
select COUNT(*)
from customer_orders_
where exclusion_1 is not null or exclusion_2 is not null or extra_1 is not null or extra_2 is not null  

/*no change*/
select COUNT(*)
from customer_orders_
where exclusion_1 is null AND exclusion_2 is null AND extra_1 is null AND extra_2 is  null  

/*How many pizzas were delivered that had both exclusions and extras?*/
select count(*)
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null AND (exclusion_1 is not null OR  exclusion_2 IS NOT NULL) AND (extra_1 is not null OR  extra_2 IS NOT NULL)

/*What was the total volume of pizzas ordered for each hour of the day?*/
select hours_of_order = DATEPART(hour,order_time),volume_per_hour = COUNT(*)
from customer_orders_
group by DATEPART(HOUR,order_time)
order by volume_per_hour desc

/*What was the volume of orders for each day of the week?*/
select day_of_week = DATENAME(WEEKDAY,date_ordered),volume_per_hour = COUNT(*)
from customer_orders_
group by DATENAME(WEEKDAY,date_ordered)
order by volume_per_hour desc

/*How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/
SELECT  starting_week = DATENAME(WEEK,registration_date), COUNT(*) number_of_signed_up_runners
FROM runners
group by DATENAME(WEEK,registration_date)

/*What was the average time in minutes it took for each runner to arrive at the Pizza*/
select r.runner_id, avg( datediff(minute,(DATEADD(hour,-1,c.order_time)),(DATEADD(hour,-1,r.pick_up_time))))
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by r.runner_id

/*Is there any relationship between the number of pizzas and how long the order takes to prepare?*/
select c.order_id,r.distance_km, sum(datediff(minute,(DATEADD(hour,-1,c.order_time)),(DATEADD(hour,-1,r.pick_up_time)))), COUNT(*)
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by c.order_id,r.distance_km
/*the more the orders the more the time use to prepare*/

/*What was the average distance travelled for each customer?*/
select c.customer_id,avg(r.distance_km) average_distance
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by c.customer_id

/*What was the difference between the longest and shortest delivery times for all orders?*/
select max(r.distance_km)- min(r.distance_km) difference_bet_long_short
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by c.customer_id

/*What was the average speed for each runner for each delivery and do you notice any trend for these values?*/
/*speed is distance over time 
insight- runnner 2 had the overall highest delivery average
         followed by runner 1*/
select r.runner_id,customer_id,average_speed_km_hr=round(avg(r.distance_km/(cast(r.duration_minutes as float)/60)) ,2)
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by r.runner_id,customer_id
having  round(avg(r.distance_km/(cast(r.duration_minutes as float)/60)) ,2) is not null 
order by customer_id


/*What is the successful delivery percentage for each runner?*/

select *,(cast((cast(fin_table.deliveries as float)/fin_table.total)*100 as varchar)+ '%') percentage_per_runner
from(Select *
from (select r.runner_id,count(*) deliveries
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.runner_id) table1 

cross join 

(select  SUM(tab.deliveries) total
from 
(select r.runner_id,count(*) deliveries
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.runner_id)
tab) table2
)fin_table

/*second approach using the window function*/
select *,SUM(tab.deliveries) over(partition by (select null)) total_deliveries_per_runner,
((cast((cast(tab.deliveries as float)/SUM(tab.deliveries) over(partition by (select null)))*100 as varchar)+'%')) as deliveries_percentage 
from 
(select r.runner_id,count(*) deliveries
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.runner_id)tab


/*What are the standard ingredients for each pizza?*/
select * from pizza_recipes1

select * from pizza_names

select * from pizza_toppings

select * from customer_orders_
/*standard ingredient for pizza 1*/
select distinct pn.pizza_id,cast(pt.topping_name as varchar) basic_ingredient,pn.pizza_name,pr1.topping
from customer_orders_ c
full join pizza_recipes pr
on c.pizza_id = pr.pizza_id
full join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
full join pizza_toppings pt
on pt.topping_id = pr1.topping
full join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_id = 1

/*standard ingredient for pizza 1*/
select distinct pn.pizza_id,cast(pt.topping_name as varchar) basic_ingredient,pn.pizza_name,pr1.topping
from customer_orders_ c
full join pizza_recipes pr
on c.pizza_id = pr.pizza_id
full join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
full join pizza_toppings pt
on pt.topping_id = pr1.topping
full join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_id = 2

/*What was the most commonly added extra?*/
/*extra 1*/
select extra_1,common_extra1=count(extra_1) over(partition by extra_1) 
order by common_extra1 desc

/*extra 2*/
select extra_2,common_extra2=count(extra_2) over(partition by extra_2)
from customer_orders_ c

order by common_extra2 desc

/*What was the most common exclusion?*/
select exclusion_2,common_exclusion2=count(exclusion_2) over(partition by exclusion_2) 
from customer_orders_ c

order by common_exclusion2 desc

/*exclusion 1*/
select exclusion_1,common_exclusion1=count(exclusion_1) over(partition by exclusion_1) 
from customer_orders_ c
order by common_exclusion1 desc


/*Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers*/
select order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_name = 'meatlovers' and exclusion_1 is null and exclusion_2 is null and extra_1 is null and extra_2 is null  

/*/*Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers - Exclude Beef*/*/
select order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name,pt.topping_id,pt.topping_name
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_name = 'meatlovers' and exclusion_1 = 3 or exclusion_2 = 3 

/*Meat Lovers - Extra Bacon*/
select distinct order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name,pt.topping_id,cast(pt.topping_name as varchar)
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_name = 'meatlovers' and (extra_1 = 1 or extra_2 = 1) 

/*Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
select  order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name,pt.topping_id,cast(pt.topping_name as varchar)
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
where pn.pizza_name = 'meatlovers' and (exclusion_1 in (1,4) or exclusion_2 in (1,4)) and (extra_1 in (6,9) or extra_2 in (6,9))

/*Generate an alphabetically ordered comma separated ingredient list for each pizza order
from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/  /*unsolved questions*/


/*('Bacon','BBQ Sauce','Beef','Cheese','Chicken','Mushrooms','Onions','Pepperoni','Peppers','Salami','Tomatoes','Tomato Sauce')
(1,2,3,4,5,6,7,8,9,10,11,12)*/
select pizza_name+':'+' '+'2x' +
CASE 
WHEN C.exclusion_1  in (1,2,3,4,5,6,7,8,9,10,11,12) then pt.topping_name  end+ ','+
case
when c.exclusion_2 in (1,2,3,4,5,6,7,8,9,10,11,12) then pt.topping_name 
end + ','+
case WHEN C.extra_1 in (1,2,3,4,5,6,7,8,9,10,11,12) then pt.topping_name end + ','+
case
when c.extra_2 in (1,2,3,4,5,6,7,8,9,10,11,12) then pt.topping_name 
end

from customer_orders_ c
Left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id



/*If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes
- how much money has Pizza Runner made so far if there are no delivery fees?*/

with cal as(
select distinct c.order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name,ro.pick_up_time,
CASE
WHEN pn.pizza_name = 'meatlovers' then 12 
when pn.pizza_name = 'vegetarian' then 10
end price
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
left join runner_orders1 ro
on ro.order_id = c.order_id
)
select '$'+cast(sum(price) as varchar) TOTAL_EARNINGS
from cal
where cal.pick_up_time is not null

/*What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra*/

SELECT  '$'+cast(SUM(tab7.price + tab7.extra_price) as varchar)
FROM (
select distinct c.order_id,c.pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,pn.pizza_name,ro.pick_up_time,
CASE
WHEN pn.pizza_name = 'meatlovers' then 12 
when pn.pizza_name = 'vegetarian' then 10
end price,
CASE
WHEN c.extra_1 is not null  then 1 
when c.extra_2 is not null then 1 else 0
end extra_price
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
left join runner_orders1 ro
on ro.order_id = c.order_id
) tab7
where tab7.pick_up_time is not null

/*The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - 
generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.*/

Create table runner_ratings
(
"order_id" integer not null primary key,
"ratings(1-10)" integer
)
insert into runner_ratings
("order_id","ratings(1-10)")
values
(1,5),
(2,7),
(3,6),
(4,6),(5,6),(6,1),(7,9),(8,3),(9,7),(10,9)

alter table dbo.customer_orders_ 
add foreign key(order_id) references dbo.runner_ratings(order_id)

/*customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/
select c.customer_id,
c.order_id,
c.order_time,
r.pick_up_time,
r.runner_id,
rr.[ratings(1-10)],
r.duration_minutes,
datediff(minute,(DATEADD(hour,-1,c.order_time)),(DATEADD(hour,-1,r.pick_up_time))) Time_between_order_and_pickup,
count(*) over(partition by (select null)) total_number_of_pizzas,
average_speed_km_hr=round(avg(r.distance_km/(cast(r.duration_minutes as float)/60)) ,2)
from customer_orders_ c
left join runner_ratings rr
on rr.order_id = c.order_id
left join dbo.runner_orders1 r
on r.order_id = c.order_id
where pick_up_time is not null
group by c.order_id,
c.order_time,
r.pick_up_time,
r.runner_id,
c.customer_id,
rr.[ratings(1-10)],
r.duration_minutes

/*If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled
- how much money does Pizza Runner have left over after these deliveries?*/

select ('$'+ cast((sum(cost1.price)- sum(cost1.actual_runner_cost)) as varchar)) money_left 
from(
select cost.order_id,cost.pizza_id,cost.runner_id,cost.pick_up_time,cost.distance_km,cost.pizza_name,cost.price,cost.runner_cost,
actual_runner_cost = case 
 when lag(cost.order_id) over(partition by order_id order by order_id) = order_id then 0  else cost.runner_cost end
from(select distinct c.order_id, c.pizza_id,ro.runner_id,ro.pick_up_time,pn.pizza_name,ro.distance_km,
runner_cost= (0.30*ro.distance_km),
CASE
WHEN pn.pizza_name = 'meatlovers' then 12 
when pn.pizza_name = 'vegetarian' then 10
end price
from customer_orders_ c
left join pizza_recipes pr
on c.pizza_id = pr.pizza_id
left join pizza_recipes1 pr1
on pr1.pizza_id = pr.pizza_id
left join pizza_toppings pt
on pt.topping_id = pr1.topping
left join pizza_names pn
on pn.pizza_id = c.pizza_id
left join runner_orders1 ro
on ro.order_id = c.order_id
left join cancellations ca
on ca.order_id = ro.order_id
) cost
)cost1
where cost1.distance_km is not null

