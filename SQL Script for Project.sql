/*Tasks Summary:

Consider all users that purchased a subscription plan for the first time between January 1 and March 31, 2023 (inclusive).
Consider all their page interactions before their purchase date.
Remove test users (ones that paid 0 dollars).
Create aliases (nicknames) for the URLs.
Combine all the pages of each session into a single user journey string.
Export all this data as a CSV with the user_id, session_id, subscription_type, and user journey */



/* Filtering User Data and Fetching First Purchase Dates
Explanation: In this step, we filter users who made their first purchase between January 1, 2023, and March 31, 2023, 
and exclude those who paid 0 dollars (test users). We also determine the type of subscription they purchased (Monthly, Quarterly, or Annual). */

WITH paid_users AS (
    SELECT 
        sp.user_id,
        sp.date_purchased AS first_purchase_date,
        CASE 
            WHEN sp.purchase_type = 0 THEN 'Monthly'
            WHEN sp.purchase_type = 1 THEN 'Quarterly'
            WHEN sp.purchase_type = 2 THEN 'Annual'
        END AS subscription_type,
        sp.purchase_price
    FROM student_purchases sp
    WHERE sp.purchase_price > 0  -- Excluding test users who paid $0
      AND sp.date_purchased BETWEEN '2023-01-01' AND '2023-03-31'  -- Filter by Q1 2023
)
SELECT * FROM paid_users


--  Extracting Relevant User Interactions Before Their First Purchase

WITH paid_users AS (
    SELECT 
        sp.user_id,
        sp.date_purchased AS first_purchase_date,
        CASE 
            WHEN sp.purchase_type = 0 THEN 'Monthly'
            WHEN sp.purchase_type = 1 THEN 'Quarterly'
            WHEN sp.purchase_type = 2 THEN 'Annual'
        END AS subscription_type,
        sp.purchase_price
    FROM student_purchases sp
    WHERE sp.purchase_price > 0  -- Excluding test users (those who paid $0)
      AND sp.date_purchased BETWEEN '2023-01-01' AND '2023-03-31'  -- Filter for Q1 2023 purchases
),
interactions_before_purchase AS (
    SELECT 
        fi.visitor_id,
        fi.session_id,
        fi.event_source_url,
        fi.event_destination_url,
        fi.event_date,
        pu.user_id,
        pu.first_purchase_date,
        pu.subscription_type
    FROM front_interactions fi
    JOIN front_visitors fv
        ON fi.visitor_id = fv.visitor_id
    JOIN paid_users pu
        ON fv.user_id = pu.user_id  -- Join to get user information
    WHERE fi.event_date < pu.first_purchase_date  -- Only consider events before the first purchase
)
-- Final result: Retrieve interactions before the user's first purchase
SELECT * FROM interactions_before_purchase;


-- CREATING ALIAS FOR URL (NICKNAME)

WITH paid_users AS (
    SELECT 
        sp.user_id,
        sp.date_purchased AS first_purchase_date,
        CASE 
            WHEN sp.purchase_type = 0 THEN 'Monthly'
            WHEN sp.purchase_type = 1 THEN 'Quarterly'
            WHEN sp.purchase_type = 2 THEN 'Annual'
        END AS subscription_type,
        sp.purchase_price
    FROM student_purchases sp
    WHERE sp.purchase_price > 0  -- Excluding test users
      AND sp.date_purchased BETWEEN '2023-01-01' AND '2023-03-31'  -- Filter for Q1 2023 purchases
),
interactions_before_purchase AS (
    SELECT 
        fi.visitor_id,
        fi.session_id,
        fi.event_source_url,
        fi.event_destination_url,
        fi.event_date,
        pu.user_id,
        pu.first_purchase_date,
        pu.subscription_type
    FROM front_interactions fi
    JOIN front_visitors fv
        ON fi.visitor_id = fv.visitor_id
    JOIN paid_users pu
        ON fv.user_id = pu.user_id
    WHERE fi.event_date < pu.first_purchase_date
),
url_aliases AS (
    -- Assuming there is a table or a derived list for URL aliases. Here we manually create it:
    SELECT 'https://365datascience.com/' AS full_url, 'Homepage' AS alias
    UNION ALL
    SELECT 'https://365datascience.com/resources-center/', 'Resources Center'
    UNION ALL
    SELECT 'https://365datascience.com/course/', 'Courses'
    UNION ALL
    SELECT 'https://365datascience.com/blog/', 'Blog'
    -- Add other URL alias mappings here...
)

-- Now we replace the URLs with their aliases
SELECT 
    ibp.visitor_id,
    ibp.session_id,
    COALESCE(ua_source.alias, ibp.event_source_url) AS event_source_url,
    COALESCE(ua_dest.alias, ibp.event_destination_url) AS event_destination_url,
    ibp.event_date,
    ibp.user_id,
    ibp.first_purchase_date,
    ibp.subscription_type
FROM interactions_before_purchase ibp
LEFT JOIN url_aliases ua_source
    ON ibp.event_source_url LIKE CONCAT(ua_source.full_url, '%')  -- Match the URL prefix
LEFT JOIN url_aliases ua_dest
    ON ibp.event_destination_url LIKE CONCAT(ua_dest.full_url, '%')  -- Match the URL prefix
    

/*Combine all the pages of each session into a single user journey string
In Task 4, we need to combine all the URLs (or their aliases) of each session into a single string, where each page visited will be concatenated in the order the user visited them. This will create a "user journey" string for each session.

Steps:
Concatenate the URLs: For each session, we will combine all the URLs visited (source and destination URLs).
Group by Session: We will group the results by session_id, so each session will have one combined user journey.
Handle Long Journeys: We need to handle the case where the journey string might be too long. We'll use GROUP_CONCAT() to aggregate the URLs, and we'll adjust its length limit to ensure that it doesn’t get truncated.
Order the pages: Ensure that the pages are ordered by event_date so the user journey reflects the correct sequence of visits. */ 


-- TASK 4: Combine all pages of each session into a single user journey string

WITH paid_users AS (
    SELECT 
        sp.user_id,
        sp.date_purchased AS first_purchase_date,
        CASE 
            WHEN sp.purchase_type = 0 THEN 'Monthly'
            WHEN sp.purchase_type = 1 THEN 'Quarterly'
            WHEN sp.purchase_type = 2 THEN 'Annual'
        END AS subscription_type,
        sp.purchase_price
    FROM student_purchases sp
    WHERE sp.purchase_price > 0  -- Excluding test users
      AND sp.date_purchased BETWEEN '2023-01-01' AND '2023-03-31'  -- Filter for Q1 2023 purchases
),
interactions_before_purchase AS (
    SELECT 
        fi.visitor_id,
        fi.session_id,
        fi.event_source_url,
        fi.event_destination_url,
        fi.event_date,
        pu.user_id,
        pu.first_purchase_date,
        pu.subscription_type
    FROM front_interactions fi
    JOIN front_visitors fv
        ON fi.visitor_id = fv.visitor_id
    JOIN paid_users pu
        ON fv.user_id = pu.user_id
    WHERE fi.event_date < pu.first_purchase_date
),
url_aliases AS (
    -- Assuming the list of URL aliases is available
    SELECT 'https://365datascience.com/' AS full_url, 'Homepage' AS alias
    UNION ALL
    SELECT 'https://365datascience.com/resources-center/', 'Resources Center'
    UNION ALL
    SELECT 'https://365datascience.com/course/', 'Courses'
    UNION ALL
    SELECT 'https://365datascience.com/blog/', 'Blog'
    -- Add other URL alias mappings here...
),
interactions_with_aliases AS (
    SELECT 
        ibp.visitor_id,
        ibp.session_id,
        COALESCE(ua_source.alias, ibp.event_source_url) AS event_source_url,
        COALESCE(ua_dest.alias, ibp.event_destination_url) AS event_destination_url,
        ibp.event_date,
        ibp.user_id,
        ibp.first_purchase_date,
        ibp.subscription_type
    FROM interactions_before_purchase ibp
    LEFT JOIN url_aliases ua_source
        ON ibp.event_source_url LIKE CONCAT(ua_source.full_url, '%')  -- Match the URL prefix
    LEFT JOIN url_aliases ua_dest
        ON ibp.event_destination_url LIKE CONCAT(ua_dest.full_url, '%')  -- Match the URL prefix
)

-- Combine all pages in each session into a single user journey string
SELECT 
    user_id,
    session_id,
    subscription_type,
    GROUP_CONCAT(DISTINCT page ORDER BY event_date SEPARATOR ' - ') AS user_journey
FROM (
    SELECT 
        iwa.user_id,
        iwa.session_id,
        iwa.subscription_type,
        -- Concatenate source and destination URLs as a single "page" entry
        CONCAT(iwa.event_source_url, ' -> ', iwa.event_destination_url) AS page,
        iwa.event_date
    FROM interactions_with_aliases iwa
    -- Only consider interactions before purchase
    WHERE iwa.event_date < iwa.first_purchase_date
) AS journey_pages
GROUP BY user_id, session_id, subscription_type
ORDER BY user_id, session_id;



