-- Build a CTE of previous season
WITH last_season AS (
    SELECT
        *
    FROM srik1981.bootcamp_nba_players
    WHERE current_season = 2000
),
-- CTE for current season
current_season AS (
    SELECT
        n.player_name,
        n.current_season
    FROM bootcamp.nba_players n
    WHERE current_season = 2001
),
-- CTE for final result
result AS (
    select 
        coalesce(y.player_name, t.player_name) AS player_name,
        coalesce(y.first_active_season, t.current_season) AS first_active_season,
        coalesce(t.current_season, y.last_active_season) AS last_active_season,
        CASE
            -- New player - No record for last season
            WHEN y.current_season IS NULL THEN ARRAY[t.current_season]
            -- Retired player - No record for season
            WHEN t.current_season IS NULL THEN y.seasons
            -- Default - Continuing player
            else y.seasons || ARRAY[t.current_season]
        END AS seasons_active,
        CASE
            -- New Players - First active season is empty and current season is not
            WHEN y.first_active_season IS NULL and t.current_season IS NOT NULL THEN 'New'
            -- Retired players - Who did not play current season but played in the last
            WHEN t.current_season IS NULL and y.last_active_season = y.current_season THEN 'Retired'
            -- Active players - Ones who played in last season and are playing in current one as well
            WHEN t.current_season - y.last_active_season = 1 THEN 'Continued Playing'
            -- Returning players - Ones who were inactive last season and active the current season
            WHEN y.last_active_season < t.current_season - 1 THEN 'Returned from Retirement'
            -- All players who stayed retired
            WHEN t.current_season IS NULL AND y.last_active_season < y.current_season THEN 'Stayed Retired'
        END AS change_tracking 
    FROM last_season y FULL OUTER JOIN current_season t
        ON t.player_name = y.player_name
)
SELECT 
    *
FROM result
