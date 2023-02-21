-- remove duplicate events
with events as 
(
    select
        event_id,
        session_id,
        user_id,
        event_timestamp,
        parse_json(event_details):event::string as event,
        parse_json(event_details):recipe_id::string as recipe_id
    from vk_data.events.website_activity
    group by 1,2,3,4,5,6
),

session_metrics as 
(
    select
        session_id,
        min(event_timestamp) as session_start,
        max(event_timestamp) as session_end,
        datediff(second, session_start, session_end) as session_length_seconds,
        nullifzero(count_if(event = 'search')) as num_search_events,
	    nullifzero(count_if(event = 'view_recipe' )) as num_recipe_views
    from events
    group by session_id
),

-- retrieves the most viewed recipe
most_viewed_recipe as 
(
    select
        date(event_timestamp) as day,
        recipe_id,
        count(*) as num_of_views
    from events
    where recipe_id is not null
    group by 1,2
    qualify row_number() over (partition by day order by num_of_views desc) = 1
),

-- final result
final_table as 
(
    select 
        date(session_metrics.session_start) as day,
        count(session_metrics.session_id) as total_sessions,
        round(avg(session_metrics.session_length_seconds),1) as avg_session_length,
        avg(session_metrics.num_search_events / session_metrics.num_recipe_views) as avg_searches_per_recipe_view,
        max(most_viewed_recipe.recipe_id) as recipe_most_viewed
    from session_metrics
    inner join most_viewed_recipe on date(session_metrics.session_start) = most_viewed_recipe.day
    group by 1
)


select * from final_table
