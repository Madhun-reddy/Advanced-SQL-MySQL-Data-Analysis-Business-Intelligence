use mavenfuzzyfactory;

select
	website_session_id,
    created_at,
    hour(created_at) as hr,
    weekday(created_at) as wkday, -- 0 = Mon, 1= Tues, etc
    case
		when weekday(created_at) = 0 then 'Monday'
        when weekday(created_at) = 0 then 'Tuesday'
        else 'other_day'
    end as clean_weekday,
    quarter(created_at) as qtr,
    month(created_at) as mo,
    date(created_at) as date,
    week(created_at) as wk
from website_sessions
where website_session_id between 150000 and 155000;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analyzing Seasonality

select
	year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where website_sessions.created_at<'2013-01-01'
group by 1,2;

select
	min(date(website_sessions.created_at)) as week_start_date,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on orders.website_session_id=website_sessions.website_session_id
where website_sessions.created_at<'2013-01-01'
group by yearweek(website_sessions.created_at);

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analyzing Business Patterns

select
	hr,
    round(avg(case when wkday=0 then website_sessions else null end),1) as mon,
    round(avg(case when wkday=1 then website_sessions else null end),1) as tue,
    round(avg(case when wkday=2 then website_sessions else null end),1) as wed,
    round(avg(case when wkday=3 then website_sessions else null end),1) as thu,
    round(avg(case when wkday=4 then website_sessions else null end),1) as fri,
    round(avg(case when wkday=5 then website_sessions else null end),1) as sat,
    round(avg(case when wkday=6 then website_sessions else null end),1) as sun 
from(
select
	date(created_at) as created_date,
    weekday(created_at) as wkday,
    hour(created_at) as hr,
    count(distinct website_session_id) as website_sessions
from website_sessions
where created_at between '2012-09-15' and '2012-11-15'
group by 1,2,3
) as daily_hourly_sessions
group by 1
order by 1;

-- My Approach
select
	hour(created_at),
	count(distinct case when weekday(created_at)=0 then website_session_id else null end) as mon,
    count(distinct case when weekday(created_at)=1 then website_session_id else null end) as tue,
    count(distinct case when weekday(created_at)=2 then website_session_id else null end) as wed,
    count(distinct case when weekday(created_at)=3 then website_session_id else null end) as thu,
    count(distinct case when weekday(created_at)=4 then website_session_id else null end) as fri,
    count(distinct case when weekday(created_at)=5 then website_session_id else null end) as sat,
    count(distinct case when weekday(created_at)=6 then website_session_id else null end) as sun
from website_sessions
where created_at between '2012-09-15' and '2012-11-15'
group by 1
order by 1; 