
-- ============================================================
-- YouTube Trending Video Analytics — SQL Queries
-- Author: [Your Name]
-- Dataset: YouTube Trending Videos (USvideos.csv)
-- Tool: SQLite via pandasql in Google Colab
-- ============================================================


-- Q1: Category Performance Ranked
-- Business question: Which content categories reach the most viewers?
SELECT
    category_name,
    COUNT(*)                          AS total_videos,
    ROUND(AVG(views), 0)              AS avg_views,
    ROUND(AVG(engagement_rate), 2)    AS avg_engagement_pct,
    ROUND(AVG(days_to_trend), 1)      AS avg_days_to_trend,
    CASE
        WHEN AVG(views) >= 1000000 THEN 'Tier 1 — High reach'
        WHEN AVG(views) >= 500000  THEN 'Tier 2 — Mid reach'
        ELSE                            'Tier 3 — Lower reach'
    END AS reach_tier
FROM df
WHERE category_name IS NOT NULL
GROUP BY category_name
HAVING COUNT(*) >= 20
ORDER BY avg_views DESC;


-- Q2: Most Consistent Channels
-- Business question: Which channels reliably produce trending videos?
SELECT
    channel_title,
    COUNT(*)                                               AS videos_trending,
    ROUND(AVG(views), 0)                                   AS avg_views,
    ROUND(CAST(AVG(views) AS FLOAT) / MAX(views), 3)       AS consistency_score
FROM df
GROUP BY channel_title
HAVING COUNT(*) >= 3
ORDER BY consistency_score DESC, avg_views DESC
LIMIT 20;


-- Q3: Engagement Paradox (CTE)
-- Business question: Do high-view videos also have high engagement?
WITH video_tiers AS (
    SELECT
        views,
        engagement_rate,
        CASE
            WHEN views >= 5000000  THEN 'Viral (5M+)'
            WHEN views >= 1000000  THEN 'Hit (1M-5M)'
            WHEN views >= 500000   THEN 'Strong (500K-1M)'
            ELSE                        'Average (under 500K)'
        END AS view_tier,
        CASE
            WHEN engagement_rate >= 10 THEN 'Very high (10%+)'
            WHEN engagement_rate >= 5  THEN 'High (5-10%)'
            WHEN engagement_rate >= 2  THEN 'Medium (2-5%)'
            ELSE                            'Low (under 2%)'
        END AS engagement_tier
    FROM df WHERE views > 0
)
SELECT
    view_tier, engagement_tier,
    COUNT(*) AS video_count,
    ROUND(AVG(engagement_rate), 2) AS avg_eng_pct
FROM video_tiers
GROUP BY view_tier, engagement_tier
ORDER BY avg_eng_pct DESC;


-- Q4: Publishing Timing (Window Functions)
-- Business question: Does day of publishing affect performance?
SELECT
    publish_day_of_week,
    COUNT(*)                                         AS videos,
    ROUND(AVG(views), 0)                             AS avg_views,
    RANK() OVER (ORDER BY AVG(views) DESC)           AS views_rank,
    RANK() OVER (ORDER BY AVG(engagement_rate) DESC) AS engagement_rank
FROM df
WHERE publish_day_of_week IS NOT NULL
GROUP BY publish_day_of_week
ORDER BY avg_views DESC;


-- Q5: Virality Speed Segments
-- Business question: Does trending faster lead to more total views?
WITH speed_segments AS (
    SELECT views, engagement_rate, days_to_trend,
        CASE
            WHEN days_to_trend = 0   THEN '1. Same day'
            WHEN days_to_trend <= 2  THEN '2. Within 2 days'
            WHEN days_to_trend <= 7  THEN '3. Within a week'
            WHEN days_to_trend <= 14 THEN '4. Within 2 weeks'
            ELSE                          '5. Slow burn (15+ days)'
        END AS speed_bucket
    FROM df WHERE days_to_trend BETWEEN 0 AND 30
)
SELECT speed_bucket, COUNT(*) AS videos,
    ROUND(AVG(views), 0) AS avg_views,
    ROUND(AVG(engagement_rate), 2) AS avg_engagement_pct
FROM speed_segments
GROUP BY speed_bucket ORDER BY speed_bucket;


-- Q6: Category Head-to-Head
-- Business question: How do top categories compare on reach vs loyalty?
SELECT
    category_name,
    COUNT(*) AS videos,
    ROUND(AVG(views), 0) AS avg_views,
    ROUND(AVG(engagement_rate), 2) AS avg_engagement_pct,
    ROUND(100.0 * SUM(CASE WHEN views >= 5000000 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS viral_rate_pct
FROM df
WHERE category_name IN ('Music','News & Politics',
                        'Entertainment','Gaming','Comedy')
GROUP BY category_name
ORDER BY avg_views DESC;
