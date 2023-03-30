# Introduction
Danny Ma Provided several data sets to help practice SQl and I partook in the Challenge.This is the 2nd week challenge that helps Danny's Imaginary pizza house.
Danny had his data but needed cleaning in order to make meaningful insights from it.

**DISCLAIMER;**  this is not a real data
## Problem Statement

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/pizza_pic.png)




## Skills Demonstrated

One of the most vital lessons or skill was planning and breaking tasks into smaller ones. This is particularly important in data analysis as it helps prevent one from being overwhelmed, creates measurable outcomes, and promotes accountability.

To achieve the objectives of the project, I used three data normalization guidelines, namely 

* 1NF
* 2NF
* 3NF

I applied the following techniques to normalize the data:

1. Split rows with multiple values using the STRING_SPLIT() function

OLD_PIZZA_RECIPES | NEW_PIZZA_RECIPES
----------------- | -----------------
![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/old_pizza_recipes_table.png)   | ![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/new_pizza_recipes_table.png)

`select pizza_id , cast(trim(value) as int) as topping
into pizza_recipes1
from dbo.pizza_recipes
cross apply
string_split(cast(toppings as varchar),',')
order by topping asc`

2. Delete duplicate rows using the ROW_NUMBER() function.

DUPLICATE ROWS | NON-DUPLICATED ROWS
----|---
![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/DUPLICATE%20TABLE.png)| ![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/new_customer_orders_table.png)

`delete tab6
from  ( 
select *,
row_num= ROW_NUMBER() over(partition by order_id,customer_id,pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,order_time,date_ordered order by (select null)) 
from dbo.customer_orders_
) tab6
where row_num > 1`

3. Create new tables from select statements (existing tables).

PARENT TABLE | EXTRACTED TABLE
----|----
![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/old_runners_table.png)| ![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/new_cancellations_table.png)

`INSERT INTO customer_orders_
 select  distinct *
 from dbo.customer_orders_
 group by order_id,customer_id,pizza_id,exclusion_1,exclusion_2,extra_1,extra_2,order_time,date_ordered
 having COUNT(*) > 1`
 
 `create table runner_orders1
as
select 
order_id,
runner_id,
substring( CAST(pickup_time as varchar),CHARINDEX(' ',  CAST(pickup_time as varchar), 9 ),LEN( CAST(pickup_time as varchar))) order_time,
LEFT(cast(pickup_time as varchar),CHARINDEX(' ', cast(pickup_time as varchar),8)) date_1,
cast(LEFT(duration,2) as int) duration_minutes,
cast(REPLACE(distance,'km','') as decimal) distance_km
from dbo.runner_orders`

4. Create primary and foreign keys and establish relationships between tables using these keys.

OLD RELATIONSHIP DIAGRAM | NEW RELATIONSHIP DIAGRAM
--------------|------------------
![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/old_relationship_table.png)| ![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/new_relationship_table.png)

`alter table dbo.runner_orders1
add FOREIGN KEY(runner_id) REFERENCES dbo.runners(runner_id)`

`alter table dbo.runner_orders1
add primary key(order_id)`

* Other cleaning Queries can be found in the  [link](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/danny%20ma%20week%202%20cleaning.sql)


## Analysis
After the normalization process, I was able to help Danny's Pizza answer some crucial questions, such as:

* What is the successful delivery percentage for each runner?

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/percentage_of%20_deliveries.png)

`select *,SUM(tab.deliveries) over(partition by (select null)) total_deliveries_per_runner,
((cast((cast(tab.deliveries as float)/SUM(tab.deliveries) over(partition by (select null)))*100 as varchar)+'%')) as deliveries_percentage 
from 
(select r.runner_id,count(*) deliveries
from dbo.customer_orders_ cu
left join dbo.runner_orders1 r
on r.order_id = cu.order_id
left join dbo.cancellations c
on r.order_id = c.order_id
where cancellation is null
group by r.runner_id)tab`

* How many pizzas were ordered?

  12 Pizzas were ordered

`select COUNT(*)
from dbo.customer_orders_ c`

* What was the volume of orders for each day of the week?

  Wednesday had the maximum number of orders, 5 in total

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/volume_of%20_orders.png)

`select day_of_week = DATENAME(WEEKDAY,date_ordered),volume_per_hour = COUNT(*)
from customer_orders_
group by DATENAME(WEEKDAY,date_ordered)
order by volume_per_hour desc`

* How many runners signed up for each one-week period? (i.e., the week starting on January 1, 2021)

  weeks 1 and 3 had one runners each signing up
  and week 2 had two runners signing up

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/signed_up.png)

`SELECT  starting_week = DATENAME(WEEK,registration_date), COUNT(*) number_of_signed_up_runners
FROM runners
group by DATENAME(WEEK,registration_date)`

* What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/Runner_time.png)

`select r.runner_id, avg( datediff(minute,(DATEADD(hour,-1,c.order_time)),(DATEADD(hour,-1,r.pick_up_time)))) arrival_time
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
group by r.runner_id`

* Is there any relationship between the number of pizzas and how long the order takes to prepare?

  there was a directly proportional relationship between number of pizzas and preparation time

![alt text](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/relationship%20of%20preparations.png)

`select c.order_id,r.distance_km, sum(datediff(minute,(DATEADD(hour,-1,c.order_time)),(DATEADD(hour,-1,r.pick_up_time)))) time_in_minutes, COUNT(*) as number_of_orders
from customer_orders_ c
left join runner_orders1 r
on c.order_id = r.order_id
where r.distance_km is not null
group by c.order_id,r.distance_km`

* other queries to more questions can be found in the [link](https://github.com/SETHADD/Case-Study-2---Pizza-Runner/blob/main/danny%20ma%20week%202.sql)


## Conclusion

Overall, this project was a great experience, and I am glad to have had the opportunity to work on it. I learned a lot, and I hope that my work can help others in their future data analysis projects.
Credit to Danny Ma
find the Data set and questions [here](https://8weeksqlchallenge.com/case-study-2/)
