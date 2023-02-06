-- Select customers that can place order
with cust_addy as (select * from vk_data.customers.customer_address as ca
where ca.customer_city is not null and ca.customer_state is not null),

cust_info as
(select cd.customer_id, cd.first_name, cd.last_name, cd.email,
cust_addy.customer_city, cust_addy.customer_state
from vk_data.customers.customer_data as cd
join cust_addy 
on cd.customer_id = cust_addy.customer_id),

cities as 
(
select * from vk_data.resources.us_cities
),
-- Get Customers lat and long
cust_geo_info as 
(select cust_info.*, cities.long, cities.lat from 
cust_info
join cities
on replace(upper(cust_info.customer_city), ' ', '') = replace(cities.city_name, ' ', '')
and cust_info.customer_state = cities.state_abbr
),


-- get suppliers lat and long
suppliers as 
(
select * from vk_data.suppliers.supplier_info
),

suppliers_geo_info as 
(select suppliers.*, cities.long as sup_long, cities.lat as sup_lat from 
suppliers
join cities
on replace(upper(suppliers.supplier_city), ' ', '') = replace(cities.city_name, ' ', '')
and suppliers.supplier_state = cities.state_abbr
),

-- cross join
cust_sup as 
(
select cust_geo_info.*, suppliers_geo_info.*
from cust_geo_info
cross join suppliers_geo_info
),

-- compute distances between customer and each supplier
cust_sup_distances as
(
select cust_sup.*,
ST_DISTANCE(ST_POINT(cust_sup.long, cust_sup.lat), 
                    ST_POINT(cust_sup.sup_long, cust_sup.sup_lat)) as distances
from cust_sup
),

-- execute window function
window_cust_sup as
(
select cust_sup_distances.*,
row_number()
over(partition by cust_sup_distances.first_name, cust_sup_distances.last_name order by cust_sup_distances.distances) as min_distance
from cust_sup_distances
)

select window_cust_sup.customer_id,
window_cust_sup.last_name,
window_cust_sup.email,
window_cust_sup.supplier_id,
window_cust_sup.supplier_name,
cast(window_cust_sup.distances as numeric)/1000 as distance
from window_cust_sup
where window_cust_sup.min_distance = 1;
