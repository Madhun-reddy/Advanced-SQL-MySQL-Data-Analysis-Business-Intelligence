-- Mid-course Project

use mavenfuzzyfactory;

select * from website_sessions;

select * from orders;

/* 
1. Gsearch seems to be the biggest driver of our business. Could you pull monthly
trends for gsearch sessions and orders so that we can showcase the growth there?
*/
select 
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rt
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where
	website_sessions.created_at<'2012-11-27'
    and website_sessions.utm_source='gsearch'
group by 1,2;

/*
2. Next, it would be great to see a similar monthly trend for gsearch, but this time splitting out nonbrand
and brand campaigns seprately. I am wondering if brand is picking up at all. If so, this is a good story to tell.
*/

select 
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when utm_campaign='nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
    count(distinct case when utm_campaign='nonbrand' then orders.order_id else null end) as nonbrand_orders,
    count(distinct case when utm_campaign='brand' then website_sessions.website_session_id else null end) as brand_sessions,
    count(distinct case when utm_campaign='brand' then orders.order_id else null end) as brand_orders
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where
	website_sessions.created_at<'2012-11-27'
    and website_sessions.utm_source='gsearch'
group by 1,2;

/* 
3. while we're on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?
I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/

select 
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when device_type='desktop' then website_sessions.website_session_id else null end) as desktop_sessions,
    count(distinct case when device_type='desktop' then orders.order_id else null end) as desktop_orders,
    count(distinct case when device_type='mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
    count(distinct case when device_type='mobile' then orders.order_id else null end) as mobile_orders
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where
	website_sessions.created_at<'2012-11-27'
    and website_sessions.utm_source='gsearch'
    and website_sessions.utm_campaign='nonbrand'
group by 1,2;

/*
4. I'm worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch.
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/

-- first, finding the various utm sources and referees to see the traffic we're getting

select distinct 
	utm_source,
    utm_campaign,
    http_referer
from website_sessions
where created_at<'2012-11-27';

select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when utm_source='gsearch' then website_sessions.website_session_id else null end) as gsearch_sessions,
    count(distinct case when utm_source='bsearch' then website_sessions.website_session_id else null end) as bsearch_sessions,
    count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_sessions,
    count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_sessions
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where
	website_sessions.created_at<'2012-11-27'
    group by 1,2;
    
/*
5. I'd like to tell the story of our website performance improvements over the course of the first 8 months.
Could you pull session to order conversion rates, by month?

*/

select 
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where
	website_sessions.created_at<'2012-11-27'
group by 1,2;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
6. For the gsearch lander test, please estimate the revenue that test earned use
*/

use mavenfuzzyfactory;

select distinct pageview_url from website_pageviews;

select 
	min(website_pageview_id) as first_test_pv
from website_pageviews
where
	pageview_url='/lander-1';

create temporary table first_test_pageviews    
select
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions
		on website_sessions.website_session_id=website_pageviews.website_session_id
        and website_sessions.created_at<'2012-07-28'
        and website_pageviews.website_pageview_id >= 23504
        and utm_source='gsearch'
        and utm_campaign='nonbrand'
group by
1;

select * from first_test_pageviews;

create temporary table nonbrand_test_sessions_w_landing_pages
select
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_test_pageviews
	left join website_pageviews
		on website_pageviews.website_pageview_id=first_test_pageviews.min_pageview_id
where
	website_pageviews.pageview_url in ('/home','/lander-1');
    
-- then we make a table to bring in orders
create temporary table nonbrand_test_sessions_w_orders
select
	nonbrand_test_sessions_w_landing_pages.website_session_id,
    nonbrand_test_sessions_w_landing_pages.landing_page,
    orders.order_id
from nonbrand_test_sessions_w_landing_pages
	left join orders
		on orders.website_session_id=nonbrand_test_sessions_w_landing_pages.website_session_id;

-- to find the difference between conversion rates
	
select
	landing_page,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as conv_rate
from nonbrand_test_sessions_w_orders
group by 1;

-- .0318 for /home, vs .0406 for /lander-1
-- .0087 additional orders per session

-- finding the most reent pageview for gsearch nonbrand where the traffic was sent to /home

select
	max(website_sessions.website_session_id) as most_recent_gsearch_nonbrand_home_pageview
from website_sessions
	left join website_pageviews
		on website_pageviews.website_session_id=website_sessions.website_session_id
where utm_source='gsearch'
	and utm_campaign='nonbrand'
    and pageview_url='/home'
    and website_sessions.created_at<'2012-11-27';
    
-- max website_session_id = 17145 17:27

select
	count(website_session_id) as session_since_test
from website_sessions
where created_at<'2012-11-27'
	and website_session_id > 17145
    and utm_source='gsearch'
    and utm_campaign='nonbrand';
    
-- 22,972 website sessions since the test

-- X .0087 incremental conversion = 202 incremental orders since 7/29
	-- roughly 4 months, si roughly 50 extra orders per month, Not bad!
    
/*
7. For the landing page test you analyzed previously, it would be great to show a full conversion funnel
from each of the two pages to orders. you can use the same time period you analyzed last time (jun 19 - jul 28).
*/

select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url='/home' then 1 else 0 end as homepage,
    case when pageview_url='/lander-1' then 1 else 0 end as custom_lander,
    case when pageview_url='/products' then 1 else 0 end as products_page,
    case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url='/cart' then 1 else 0 end as cart_page,
    case when pageview_url='/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url='/billing' then 1 else 0 end as billing_page,
    case when pageview_url='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.utm_source='gsearch'
	and website_sessions.utm_campaign='nonbrand'
--    and website_sessions.created_at between '2012-06-28' and '2012-06-19'
	and website_sessions.created_at<'2012-07-28'
    and website_sessions.created_at>'2012-06-19'
order by 1,3;

create temporary table session_level_made_it_flagged
select
	website_session_id,
    max(homepage) as saw_homepage,
    max(custom_lander) as saw_custom_lander,
    max(products_page) as product_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(thankyou_page) as thankyou_made_it
from(
select
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url='/home' then 1 else 0 end as homepage,
    case when pageview_url='/lander-1' then 1 else 0 end as custom_lander,
    case when pageview_url='/products' then 1 else 0 end as products_page,
    case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url='/cart' then 1 else 0 end as cart_page,
    case when pageview_url='/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url='/billing' then 1 else 0 end as billing_page,
    case when pageview_url='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.utm_source='gsearch'
	and website_sessions.utm_campaign='nonbrand'
--    and website_sessions.created_at between '2012-06-28' and '2012-06-19'
	and website_sessions.created_at<'2012-07-28'
    and website_sessions.created_at>'2012-06-19'
order by 1,3
) as pageview_level
group by website_session_id;

select * from session_level_made_it_flagged;

-- then this as final output part 2 - click rates

select
	case
		when saw_homepage=1 then 'saw_homepage'
        when saw_custom_lander=1 then 'saw_custom_lander'
        else 'uh oh.. check logic'
	end as segment,
    count(distinct website_session_id) as sessions,
    count(distinct case when product_made_it=1 then website_session_id else null end) as to_products,
    count(distinct case when mrfuzzy_made_it=1 then website_session_id else null end) as to_mrfuzzy,
    count(distinct case when cart_made_it=1 then website_session_id else null end) as to_cart,
    count(distinct case when shipping_made_it=1 then website_session_id else null end) as to_shipping,
    count(distinct case when billing_made_it=1 then website_session_id else null end) as to_billing,
    count(distinct case when thankyou_made_it=1 then website_session_id else null end) as to_thankyou
from session_level_made_it_flagged
group by 1;

/*
8. I'd love for you to quantify the impact of our billing test, as well, please analyze the lift generated
from the test (Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number
of billing page sessions for the past month to understand monthly impact
*/

select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on orders.website_session_id=website_pageviews.website_session_id
where website_pageviews.created_at > '2012-09-10'
	and website_pageviews.created_at< '2012-11-10'
    and website_pageviews.pageview_url in ('/billing','/billing-2');

select 
	billing_version_seen,
    count(distinct website_session_id) as sessions,
    sum(price_usd)/count(distinct website_session_id) as revenue_per_billing_page_seen
from(
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on orders.website_session_id=website_pageviews.website_session_id
where website_pageviews.created_at > '2012-09-10'
	and website_pageviews.created_at< '2012-11-10'
    and website_pageviews.pageview_url in ('/billing','/billing-2')
) as billing_pageviews_and_order_data
group by 1;

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: $8.51 per billing page view

select
	count(website_session_id) as billing_sessions_past_month
from website_pageviews
where website_pageviews.pageview_url in ('/billing','/billing-2')
	and created_at between '2012-10-27' and '2012-11-27';
    
-- 1,193 billing sessions past month
-- LIFT: $8.51 per billing session
-- value of billing test: $10,160 over the past month