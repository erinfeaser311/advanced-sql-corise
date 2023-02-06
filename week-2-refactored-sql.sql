-- get all active customers who have responded to a survey and count their total food preferences
with customer_food_pref_count as (   
    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1  
)

-- get chicago geo
, chicago_geo as (
    select 
        geo_location
    from vk_data.resources.us_cities 
    where (city_name = 'CHICAGO' and state_abbr = 'IL')
)

-- get gary, in geo
, gary_geo as (
    select 
        geo_location
    from vk_data.resources.us_cities 
    where (city_name = 'GARY' and state_abbr = 'IN')
)

-- get all active customers who live in specified states in KY, CA, and TX and each of their respective distances in miles to chicago and gary, in
select 
    first_name || ' ' || last_name as customer_name,
    ca.customer_city,
    ca.customer_state,
    s.food_pref_count,
    (st_distance(us.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
    (st_distance(us.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles
from vk_data.customers.customer_address as ca
    inner join vk_data.customers.customer_data c on ca.customer_id = c.customer_id
    left join vk_data.resources.us_cities us 
        on lower(trim(ca.customer_state)) = lower(trim(us.state_abbr))
            and lower(trim(ca.customer_city)) = lower(trim(us.city_name))
    inner join customer_food_pref_count s on c.customer_id = s.customer_id
    cross join chicago_geo chic 
    cross join gary_geo gary
where 
    (ca.customer_state = 'CA' and (trim(us.city_name) ilike '%oakland%' or trim(us.city_name) ilike '%pleasant hill%'))
    or
    (ca.customer_state = 'TX' and (trim(us.city_name) ilike '%arlington%' or trim(us.city_name) ilike '%brownsville%'))
    or
    (ca.customer_state = 'KY' and (trim(us.city_name) ilike '%concord%' or trim(us.city_name) ilike '%georgetown%' or trim(us.city_name) ilike '%ashland%'))
    
-- this query returns 19 customers instead of 25, like the original, because of changes made to parentheses in the WHERE clause
