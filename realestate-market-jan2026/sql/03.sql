
-- name: get-district-data
with data as (
    select 
      r.realestate_id, 
      l.listing_id,
      l.span as listing_span, 
      lp.span as listing_price_span, 
      lp.price, 
      u.district_id,
      r.square_meters, 
      rt.name as realestate_type_name, 
      c.name as city_name,
      case when rt.name in ('Fjölbýlishús', 'Hæð') then 'Fjölbýli' else 'Sérbýli' end as realestate_category_name,
      first_value(lp.price) over (partition by l.listing_id order by lp.span) as first_price,
      lag(lp.price) over (partition by l.listing_id order by lp.span) as previous_price,
      count(lp.span) over (partition by l.listing_id order by lp.span) as change_counter
    from listings l
    join listing_prices lp
    on l.realestate_id = lp.realestate_id
    and l.span && lp.span
    join realestates r
    on lp.realestate_id = r.realestate_id
    join realestate_types rt
    on r.realestate_type_id = rt.realestate_type_id
    join units u 
    on r.unit_id = u.unit_id
    join addresses a
    on u.address_id = a.address_id
    join lands la
    on a.land_id = la.land_id
    join postals p
    on la.postal_id = p.postal_id
    join cities c
    on p.city_id = c.city_id
    join regions reg
    on c.region_id = reg.region_id
    where rt.name in ('Fjölbýlishús', 'Par/Raðhús', 'Hæð', 'Einbýlishús')
      and reg.name = 'Höfuðborgarsvæðið'
      and u.district_id is not null
), data2 as (
  select *, sum(((price < previous_price) and (price < first_price))::int) over (partition by listing_id order by listing_price_span) as price_lower_counter
  from data
)
select 
    d.date::date as date,
    realestate_category_name,
    district_id,
    count(case when price_lower_counter > 0 then realestate_id else null end) as listings_lower_price,
    count(distinct realestate_id) as listings,
    avg(price_lower_counter) as average_lower_counter,
    avg((d.date::date - lower(listing_span)::date)::int) as listing_days
from data2
cross join generate_series(lower(listing_price_span)::date, (upper(listing_price_span)-make_interval(days:=1))::date, make_interval(days:=1)) as d(date)
group by d.date, realestate_category_name, district_id
order by d.date desc, realestate_category_name, district_id