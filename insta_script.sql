-- 1. How many rows and columns?
SELECT COUNT(*) as total_rows FROM dummy;

-- 2. See sample data
SELECT * FROM dummy LIMIT 10;

-- 3. Check all column names and data types
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'dummy'
AND table_schema = 'insta_db'
ORDER BY ordinal_position;

-- 4. Quick statistical overview of numeric columns
SELECT
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(account_creation_year) as earliest_account,
    MAX(account_creation_year) as latest_account,
    MIN(age) as min_age,
    MAX(age) as max_age,
    ROUND(AVG(age), 2) as avg_age
FROM dummy;

-- 5. Check duplicate user_ids
SELECT user_id, COUNT(*) as cnt
FROM dummy
GROUP BY user_id
HAVING cnt > 1
ORDER BY cnt DESC;

-- 6. Check fully duplicate rows
    SELECT user_id, age, gender, country
    FROM dummy
    GROUP BY user_id, age, gender, country
    HAVING COUNT(*) > 1;

-- 7. How many unique vs total
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(*) - COUNT(DISTINCT user_id) as duplicate_rows
FROM dummy;

-- 8. Quick missing % for key columns
SELECT
    ROUND(SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as age_missing_pct,
    ROUND(SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as gender_missing_pct,
    ROUND(SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as country_missing_pct,
    ROUND(SUM(CASE WHEN income_level IS NULL OR income_level = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as income_missing_pct
FROM dummy;

-- 9. Statistical summary for ALL numeric columns
SELECT
    -- Age
    MIN(age) as age_min, MAX(age) as age_max, ROUND(AVG(age),2) as age_avg, ROUND(STDDEV(age),2) as age_std,
    -- Sleep
    MIN(sleep_hours_per_night) as sleep_min, MAX(sleep_hours_per_night) as sleep_max, ROUND(AVG(sleep_hours_per_night),2) as sleep_avg,
    -- BMI
    MIN(body_mass_index) as bmi_min, MAX(body_mass_index) as bmi_max, ROUND(AVG(body_mass_index),2) as bmi_avg,
    -- Engagement
    MIN(user_engagement_score) as eng_min, MAX(user_engagement_score) as eng_max, ROUND(AVG(user_engagement_score),2) as eng_avg,
    -- Session
    MIN(average_session_length_minutes) as session_min, MAX(average_session_length_minutes) as session_max,
    -- Followers
    MIN(followers_count) as followers_min, MAX(followers_count) as followers_max, ROUND(AVG(followers_count),2) as followers_avg
FROM dummy;

-- 10. Detect outliers using IQR method
--  Get Q1 and Q3 for age
SELECT
    MAX(CASE WHEN quartile = 1 THEN age END) AS Q1,
    MAX(CASE WHEN quartile = 3 THEN age END) AS Q3,
    MAX(CASE WHEN quartile = 3 THEN age END) - MAX(CASE WHEN quartile = 1 THEN age END) AS IQR
FROM (
    SELECT age,
           NTILE(4) OVER (ORDER BY age) AS quartile
    FROM dummy
    WHERE age IS NOT NULL
) AS quartiles;

-- Flag outliers (age example)
SELECT user_id, age
FROM dummy
WHERE age < 10 OR age > 90;

-- 11. Flag unrealistic values
SELECT user_id, sleep_hours_per_night
FROM dummy
WHERE sleep_hours_per_night > 16 OR sleep_hours_per_night < 2;

-- 12. Flag unrealistic values
SELECT user_id, body_mass_index
FROM dummy
WHERE body_mass_index < 10 OR body_mass_index > 70;

-- 13. Check all unique values in categorical columns
SELECT gender, COUNT(*) as cnt FROM dummy GROUP BY gender ORDER BY cnt DESC;
SELECT country, COUNT(*) as cnt FROM dummy GROUP BY country ORDER BY cnt DESC;
SELECT education_level, COUNT(*) as cnt FROM dummy GROUP BY education_level ORDER BY cnt DESC;
SELECT employment_status, COUNT(*) as cnt FROM dummy GROUP BY employment_status ORDER BY cnt DESC;
SELECT income_level, COUNT(*) as cnt FROM dummy GROUP BY income_level ORDER BY cnt DESC;
SELECT relationship_status, COUNT(*) as cnt FROM dummy GROUP BY relationship_status ORDER BY cnt DESC;
SELECT diet_quality, COUNT(*) as cnt FROM dummy GROUP BY diet_quality ORDER BY cnt DESC;
SELECT urban_rural, COUNT(*) as cnt FROM dummy GROUP BY urban_rural ORDER BY cnt DESC;
SELECT content_type_preference, COUNT(*) as cnt FROM dummy GROUP BY content_type_preference ORDER BY cnt DESC;
SELECT subscription_status, COUNT(*) as cnt FROM dummy GROUP BY subscription_status ORDER BY cnt DESC;

-- 14. CREATE BACKUP BEFORE TOUCHING ANYTHING
CREATE TABLE dummy_backup AS SELECT * FROM dummy;

-- 15. Verify backup
SELECT COUNT(*) FROM dummy_backup;

-- 16. Remove duplicates keeping the first occurrence
DELETE d1 FROM dummy d1
INNER JOIN dummy d2
WHERE d1.user_id = d2.user_id
AND d1.user_id > d2.user_id;  -- assumes auto-increment id column

-- 17. Fix inconsistent casing/spacing
UPDATE dummy SET gender = TRIM(LOWER(gender));
UPDATE dummy SET country = TRIM(country);
UPDATE dummy SET education_level = TRIM(education_level);

-- 18. Standardize specific values
UPDATE dummy SET gender = 'Male' WHERE gender IN ('male', 'M', 'm', 'MALE');
UPDATE dummy SET gender = 'Female' WHERE gender IN ('female', 'F', 'f', 'FEMALE');
UPDATE dummy SET gender = 'Other' WHERE gender IN ('other', 'others', 'non-binary');

#  Tips
-- NUMERIC columns → use MEAN or MEDIAN
-- CATEGORICAL columns → use MODE (most frequent)

-- 19. Mean imputation for continuous variables
UPDATE dummy
SET sleep_hours_per_night = (
    SELECT avg_val FROM (
        SELECT ROUND(AVG(sleep_hours_per_night), 1) AS avg_val
        FROM dummy
        WHERE sleep_hours_per_night IS NOT NULL AND sleep_hours_per_night > 0
    ) AS t
)
WHERE sleep_hours_per_night IS NULL OR sleep_hours_per_night = 0;

-- 20. MODE imputation for categorical variables
UPDATE dummy
SET gender = (
    SELECT mode_val FROM (
        SELECT gender AS mode_val
        FROM dummy
        WHERE gender IS NOT NULL AND gender != ''
        GROUP BY gender
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS t
)
WHERE gender IS NULL OR gender = '';

UPDATE dummy
SET country = (
    SELECT mode_val FROM (
        SELECT country AS mode_val
        FROM dummy
        WHERE country IS NOT NULL AND country != ''
        GROUP BY country
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS t
)
WHERE country IS NULL OR country = '';

UPDATE dummy
SET education_level = (
    SELECT mode_val FROM (
        SELECT education_level AS mode_val
        FROM dummy
        WHERE education_level IS NOT NULL AND education_level != ''
        GROUP BY education_level
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS t
)
WHERE education_level IS NULL OR education_level = '';

UPDATE dummy
SET education_level = (
    SELECT mode_val FROM (
        SELECT education_level AS mode_val
        FROM dummy
        WHERE education_level IS NOT NULL AND education_level != ''
        GROUP BY education_level
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS t
)
WHERE education_level IS NULL OR education_level = '';

-- Do same pattern for: country, education_level, employment_status,
-- income_level, relationship_status, diet_quality etc.

-- Check if numeric columns stored as text
SELECT 
    DATA_TYPE, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dummy'
AND DATA_TYPE IN ('varchar', 'text', 'char');

-- Convert if needed
ALTER TABLE dummy MODIFY COLUMN age INT;
ALTER TABLE dummy MODIFY COLUMN body_mass_index DECIMAL(5,2);
ALTER TABLE dummy MODIFY COLUMN sleep_hours_per_night DECIMAL(4,1);
ALTER TABLE dummy MODIFY COLUMN user_engagement_score DECIMAL(5,2);

-- After verifying no duplicates
ALTER TABLE dummy ADD CONSTRAINT unique_user UNIQUE (user_id);

-- Add primary key if not exists
ALTER TABLE dummy ADD PRIMARY KEY (user_id);

-- Run your null audit AGAIN after cleaning
-- Counts should all be 0 now

-- Verify row counts unchanged
SELECT COUNT(*) FROM dummy;         -- should match backup
SELECT COUNT(*) FROM dummy_backup;

-- Age distribution
SELECT
    CASE
        WHEN age BETWEEN 13 AND 17 THEN 'Teen (13-17)'
        WHEN age BETWEEN 18 AND 24 THEN 'Young Adult (18-24)'
        WHEN age BETWEEN 25 AND 34 THEN 'Adult (25-34)'
        WHEN age BETWEEN 35 AND 44 THEN 'Mid Adult (35-44)'
        WHEN age BETWEEN 45 AND 60 THEN 'Older Adult (45-60)'
        ELSE '60+'
    END AS age_group,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM dummy
GROUP BY age_group
ORDER BY MIN(age);

-- Gender distribution
SELECT gender, COUNT(*) as count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dummy), 2) as pct
FROM dummy
GROUP BY gender;

-- Country distribution (Top 10)
SELECT country, COUNT(*) as users,
       ROUND(AVG(user_engagement_score), 2) as avg_engagement
FROM dummy
GROUP BY country
ORDER BY users DESC
LIMIT 10;

-- Average Instagram usage by age group
SELECT
    CASE
        WHEN age BETWEEN 13 AND 24 THEN 'Gen Z'
        WHEN age BETWEEN 25 AND 40 THEN 'Millennial'
        WHEN age BETWEEN 41 AND 56 THEN 'Gen X'
        ELSE 'Boomer+'
    END AS generation,
    ROUND(AVG(daily_active_minutes_instagram), 2) as avg_daily_minutes,
    ROUND(AVG(sessions_per_day), 2) as avg_sessions,
    ROUND(AVG(reels_watched_per_day), 2) as avg_reels,
    ROUND(AVG(stories_viewed_per_day), 2) as avg_stories,
    ROUND(AVG(posts_created_per_week), 2) as avg_posts,
    COUNT(*) as user_count
FROM dummy
GROUP BY generation
ORDER BY avg_daily_minutes DESC;

-- Content preference analysis
SELECT content_type_preference,
       COUNT(*) as users,
       ROUND(AVG(user_engagement_score), 2) as avg_engagement,
       ROUND(AVG(daily_active_minutes_instagram), 2) as avg_time_spent
FROM dummy
GROUP BY content_type_preference
ORDER BY avg_engagement DESC;

-- Peak engagement by subscription status
SELECT subscription_status,
       ROUND(AVG(user_engagement_score), 2) as avg_engagement,
       ROUND(AVG(ads_clicked_per_day), 2) as avg_ads_clicked,
       COUNT(*) as users
FROM dummy
GROUP BY subscription_status;

-- Sleep vs happiness correlation proxy
SELECT
    CASE
        WHEN sleep_hours_per_night < 6 THEN 'Poor Sleep (<6hrs)'
        WHEN sleep_hours_per_night BETWEEN 6 AND 7 THEN 'Moderate Sleep (6-7hrs)'
        WHEN sleep_hours_per_night BETWEEN 7 AND 9 THEN 'Good Sleep (7-9hrs)'
        ELSE 'Oversleep (>9hrs)'
    END AS sleep_category,
    ROUND(AVG(self_reported_happiness), 2) as avg_happiness,
    ROUND(AVG(perceived_stress_score), 2) as avg_stress,
    ROUND(AVG(daily_active_minutes_instagram), 2) as avg_instagram_time,
    COUNT(*) as users
FROM dummy
GROUP BY sleep_category
ORDER BY avg_happiness DESC;

-- Exercise vs screen time
SELECT
    CASE
        WHEN exercise_hours_per_week = 0 THEN 'Sedentary'
        WHEN exercise_hours_per_week BETWEEN 1 AND 2 THEN 'Low Activity'
        WHEN exercise_hours_per_week BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'High Activity'
    END AS activity_level,
    ROUND(AVG(daily_active_minutes_instagram), 2) as avg_instagram_mins,
    ROUND(AVG(self_reported_happiness), 2) as avg_happiness,
    ROUND(AVG(perceived_stress_score), 2) as avg_stress,
    COUNT(*) as users
FROM dummy
GROUP BY activity_level
ORDER BY avg_instagram_mins DESC;

-- BMI vs Instagram usage
SELECT
    CASE
        WHEN body_mass_index < 18.5 THEN 'Underweight'
        WHEN body_mass_index BETWEEN 18.5 AND 24.9 THEN 'Normal'
        WHEN body_mass_index BETWEEN 25 AND 29.9 THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    ROUND(AVG(daily_active_minutes_instagram), 2) as avg_instagram_mins,
    ROUND(AVG(exercise_hours_per_week), 2) as avg_exercise,
    COUNT(*) as users
FROM dummy
GROUP BY bmi_category;

-- Step 1: Set p90 threshold
SET @p90_value = (
    SELECT user_engagement_score
    FROM (
        SELECT user_engagement_score,
               ROW_NUMBER() OVER (ORDER BY user_engagement_score DESC) AS rn,
               COUNT(*) OVER () AS total
        FROM dummy
    ) AS ranked
    WHERE rn = FLOOR(total * 0.10)
    LIMIT 1
);

-- Step 2: Verify (optional)
SELECT @p90_value;

-- Step 3: Main Query
SELECT
    CASE
        WHEN user_engagement_score >= @p90_value THEN 'Top 10%'
        ELSE 'Bottom 90%'
    END                                            AS user_group,
    COUNT(*)                                       AS total_users,

    -- Demographics
    ROUND(AVG(age), 1)                             AS avg_age,
    ROUND(AVG(user_engagement_score), 2)           AS avg_engagement_score,

    -- Instagram Usage
    ROUND(AVG(daily_active_minutes_instagram), 2)  AS avg_daily_mins,
    ROUND(AVG(sessions_per_day), 2)                AS avg_sessions,
    ROUND(AVG(reels_watched_per_day), 1)           AS avg_reels,
    ROUND(AVG(stories_viewed_per_day), 1)          AS avg_stories,
    ROUND(AVG(posts_created_per_week), 1)          AS avg_posts,
    ROUND(AVG(likes_given_per_day), 1)             AS avg_likes,
    ROUND(AVG(comments_written_per_day), 1)        AS avg_comments,

    -- Social Stats
    ROUND(AVG(followers_count), 0)                 AS avg_followers,
    ROUND(AVG(following_count), 0)                 AS avg_following,
    ROUND(AVG(dms_sent_per_week), 1)               AS avg_dms_sent,

    -- Health & Wellbeing
    ROUND(AVG(self_reported_happiness), 2)         AS avg_happiness,
    ROUND(AVG(perceived_stress_score), 2)          AS avg_stress,
    ROUND(AVG(sleep_hours_per_night), 1)           AS avg_sleep,
    ROUND(AVG(exercise_hours_per_week), 1)         AS avg_exercise,
    ROUND(AVG(body_mass_index), 1)                 AS avg_bmi,

    -- Ads & Monetization
    ROUND(AVG(ads_clicked_per_day), 2)             AS avg_ads_clicked,
    ROUND(AVG(ads_viewed_per_day), 2)              AS avg_ads_viewed

FROM dummy
GROUP BY user_group
ORDER BY avg_engagement_score DESC;

-- Engagement score breakdown by income
SELECT income_level,
       ROUND(AVG(user_engagement_score), 2) as avg_engagement,
       ROUND(AVG(ads_clicked_per_day), 2) as avg_ads_clicked,
       ROUND(AVG(uses_premium_features), 2) as premium_usage_rate,
       COUNT(*) as users
FROM dummy
GROUP BY income_level
ORDER BY avg_engagement DESC;

-- Create user segments based on usage
SELECT
    CASE
        WHEN daily_active_minutes_instagram > 120 AND posts_created_per_week > 5 THEN 'Power Creator'
        WHEN daily_active_minutes_instagram > 120 AND posts_created_per_week <= 5 THEN 'Heavy Consumer'
        WHEN daily_active_minutes_instagram BETWEEN 30 AND 120 THEN 'Casual User'
        ELSE 'Low Engagement'
    END AS user_segment,
    COUNT(*) as user_count,
    ROUND(AVG(user_engagement_score), 2) as avg_engagement,
    ROUND(AVG(self_reported_happiness), 2) as avg_happiness,
    ROUND(AVG(age), 1) as avg_age,
    ROUND(AVG(followers_count), 0) as avg_followers
FROM dummy
GROUP BY user_segment
ORDER BY avg_engagement DESC;

-- Pearson correlation between two variables (manual)
SELECT
    (COUNT(*) * SUM(daily_active_minutes_instagram * self_reported_happiness)
     - SUM(daily_active_minutes_instagram) * SUM(self_reported_happiness))
    /
    (SQRT(COUNT(*) * SUM(POW(daily_active_minutes_instagram, 2)) - POW(SUM(daily_active_minutes_instagram), 2))
     * SQRT(COUNT(*) * SUM(POW(self_reported_happiness, 2)) - POW(SUM(self_reported_happiness), 2)))
    AS correlation_instagram_vs_happiness
FROM dummy;

-- Run same formula for multiple pairs:
-- instagram_time vs stress
-- instagram_time vs sleep
-- followers vs happiness
-- engagement_score vs happiness

-- Behavior by account creation year
SELECT account_creation_year,
       COUNT(*) as users,
       ROUND(AVG(followers_count), 0) as avg_followers,
       ROUND(AVG(user_engagement_score), 2) as avg_engagement,
       ROUND(AVG(daily_active_minutes_instagram), 2) as avg_daily_mins
FROM dummy
GROUP BY account_creation_year
ORDER BY account_creation_year;

WITH ranked AS (
    SELECT
        user_id,
        country,
        user_engagement_score,
        
        -- Rank within country (highest engagement = rank 1)
        RANK() OVER (PARTITION BY country ORDER BY user_engagement_score DESC) AS country_rank,
        
        -- Average engagement per country
        ROUND(AVG(user_engagement_score) OVER (PARTITION BY country), 2) AS country_avg_engagement,
        
        -- Difference from country average
        ROUND(user_engagement_score - AVG(user_engagement_score) 
              OVER (PARTITION BY country), 2) AS diff_from_avg,
        
        -- For median calculation
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY user_engagement_score ASC)  AS row_asc,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY user_engagement_score DESC) AS row_desc,
        COUNT(*) OVER (PARTITION BY country) AS total_rows

    FROM dummy
),

-- Median per country (separate CTE)
median_cte AS (
    SELECT
        country,
        ROUND(AVG(user_engagement_score), 2) AS country_median
    FROM ranked
    WHERE row_asc BETWEEN FLOOR((total_rows + 1) / 2) 
                      AND CEIL((total_rows + 1) / 2)
    GROUP BY country
)

-- Final output joining both CTEs
SELECT
    r.user_id,
    r.country,
    r.user_engagement_score,
    r.country_rank,
    r.country_avg_engagement,
    m.country_median,
    r.diff_from_avg,
    r.total_rows AS country_total_users,
    
    -- Performance label
    CASE
        WHEN r.user_engagement_score >= m.country_median 
             AND r.user_engagement_score >= r.country_avg_engagement THEN 'Above Average'
        WHEN r.user_engagement_score >= m.country_median 
             AND r.user_engagement_score < r.country_avg_engagement  THEN 'Near Average'
        ELSE 'Below Average'
    END AS performance_vs_country

FROM ranked r
JOIN median_cte m ON r.country = m.country
ORDER BY r.country, r.country_rank;

-- Running average of engagement
SELECT
    user_id,
    account_creation_year,
    user_engagement_score,
    ROUND(AVG(user_engagement_score) OVER (ORDER BY account_creation_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg
FROM dummy
ORDER BY account_creation_year;

CREATE VIEW instagram_summary AS
SELECT
    -- Demographics
    COUNT(*) as total_users,
    ROUND(AVG(age), 1) as avg_age,
    -- Usage
    ROUND(AVG(daily_active_minutes_instagram), 1) as avg_daily_mins,
    ROUND(AVG(sessions_per_day), 1) as avg_sessions,
    ROUND(AVG(user_engagement_score), 2) as avg_engagement,
    -- Health
    ROUND(AVG(sleep_hours_per_night), 1) as avg_sleep,
    ROUND(AVG(self_reported_happiness), 2) as avg_happiness,
    ROUND(AVG(perceived_stress_score), 2) as avg_stress,
    ROUND(AVG(exercise_hours_per_week), 1) as avg_exercise,
    -- Social
    ROUND(AVG(followers_count), 0) as avg_followers,
    ROUND(AVG(following_count), 0) as avg_following,
    ROUND(AVG(posts_created_per_week), 1) as avg_posts_per_week
FROM dummy;

SELECT * FROM instagram_summary;

-- Save cleaned, enriched data for visualization tools (Tableau, Power BI)
SELECT
    user_id,
    age,
    gender,
    country,
    income_level,
    education_level,
    CASE
        WHEN age BETWEEN 13 AND 24 THEN 'Gen Z'
        WHEN age BETWEEN 25 AND 40 THEN 'Millennial'
        WHEN age BETWEEN 41 AND 56 THEN 'Gen X'
        ELSE 'Boomer+'
    END AS generation,
    CASE
        WHEN daily_active_minutes_instagram > 120 AND posts_created_per_week > 5 THEN 'Power Creator'
        WHEN daily_active_minutes_instagram > 120 AND posts_created_per_week <= 5 THEN 'Heavy Consumer'
        WHEN daily_active_minutes_instagram BETWEEN 30 AND 120 THEN 'Casual User'
        ELSE 'Low Engagement'
    END AS user_segment,
    daily_active_minutes_instagram,
    user_engagement_score,
    self_reported_happiness,
    perceived_stress_score,
    sleep_hours_per_night,
    exercise_hours_per_week,
    body_mass_index
FROM dummy;

select * from dummy_backup;
select * from dummy;

describe dummy_backup;



