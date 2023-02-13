-- 1. Use CTEs to make query more readable
-- 2. Clarify use of aliases when refering to table names and columns

-- Get Store in Chicago able to process overnight order
with chicago_stores as 
(
select 
        geo_location
    from vk_data.resources.us_cities 
    where city_name = 'CHICAGO' and state_abbr = 'IL'
),

-- Get Store in Gary able to process overnight order
gary_stores as 
(
select 
        geo_location
    from vk_data.resources.us_cities 
    where city_name = 'GARY' and state_abbr = 'IN'
),

-- customers with other preferences
customer_pref as
(
    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1
)

select 
    cd.first_name || ' ' || cd.last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    customer_pref.food_pref_count,
    (st_distance(us.geo_location, chicago_stores.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(us.geo_location, gary_stores.geo_location) / 1609)::int as gary_distance_miles
from vk_data.customers.customer_address as ca
inner join vk_data.customers.customer_data as cd 
    on ca.customer_id = cd.customer_id
left join vk_data.resources.us_cities as us 
    on UPPER(rtrim(ltrim(ca.customer_state))) = upper(TRIM(us.state_abbr))
        and trim(lower(ca.customer_city)) = trim(lower(us.city_name))
inner join customer_pref
    on cd.customer_id = customer_pref.customer_id
cross join chicago_stores
cross join gary_stores
where 
    ((trim(us.city_name) ilike '%concord%' or trim(us.city_name) ilike '%georgetown%' or trim(us.city_name) ilike '%ashland%')
    and ca.customer_state = 'KY')
    or
    (ca.customer_state = 'CA' and (trim(us.city_name) ilike '%oakland%' or trim(us.city_name) ilike '%pleasant hill%'))
    or
    (ca.customer_state = 'TX' and (trim(us.city_name) ilike '%arlington%') or trim(us.city_name) ilike '%brownsville%')