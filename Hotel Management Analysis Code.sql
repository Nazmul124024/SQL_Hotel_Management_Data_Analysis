-- SQL Project: Hotel Management Analysis

-- 1) Calculating Cancellation Rate by Market Segment
[cite_start]-- This query calculates the total number of bookings and cancellations, then derives the cancellation rate for each market segment in the 2018 dataset[cite: 1].
SELECT
    t1.market_segment,
    COUNT(t1.is_canceled) AS TotalBookings,
    SUM(CASE WHEN t1.is_canceled = 1 THEN 1 ELSE 0 END) AS TotalCancellations,
    CAST(SUM(CASE WHEN t1.is_canceled = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(t1.is_canceled) AS CancellationRate
FROM
    [dbo].['2018$'] AS t1
GROUP BY
    t1.market_segment
ORDER BY
    CancellationRate DESC;

-- 2) Guest Demographics and Spending Habits
[cite_start]-- This query analyzes guest demographics by grouping bookings by the number of adults and children, and then calculates the average daily rate (ADR) for each group in the 2019 dataset[cite: 1].
SELECT
    adults,
    children,
    COUNT(*) AS NumberOfBookings,
    AVG(adr) AS AverageDailyRate
FROM
    [dbo].['2019$']
GROUP BY
    adults,
    children
ORDER BY
    NumberOfBookings DESC;

-- 3) Analyzing Booking Changes and Their Impact on Revenue
[cite_start]-- This query uses a CTE (Common Table Expression) to calculate the total booking changes and average daily rate, then estimates the revenue impact of booking changes in the 2020 dataset[cite: 1].
WITH BookingMetrics AS (
    SELECT
        reserved_room_type,
        assigned_room_type,
        SUM(booking_changes) AS TotalBookingChanges,
        AVG(adr) AS AverageDailyRate
    FROM
        [dbo].['2020$']
    GROUP BY
        reserved_room_type,
        assigned_room_type
)
SELECT
    reserved_room_type,
    assigned_room_type,
    TotalBookingChanges,
    AverageDailyRate,
    TotalBookingChanges * AverageDailyRate AS EstimatedRevenueImpact
FROM
    BookingMetrics
ORDER BY
    EstimatedRevenueImpact DESC;

-- 4) Calculating Booking Lag Time by Month
[cite_start]-- This query calculates the average lead time (lag time) for bookings, broken down by year and month, in the 2018 dataset[cite: 1].
SELECT
    arrival_date_year,
    arrival_date_month,
    AVG(lead_time) AS average_lead_time
FROM
    [dbo].['2018$']
GROUP BY
    arrival_date_year,
    arrival_date_month
ORDER BY
    arrival_date_year,
    CASE arrival_date_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END;

-- 5) Finding the Top 5 Countries with the Most Bookings
[cite_start]-- This query identifies the top 5 countries based on the total number of bookings in the 2019 dataset[cite: 1].
SELECT TOP 5
    country,
    COUNT(*) AS total_bookings
FROM
    [dbo].['2019$']
GROUP BY
    country
ORDER BY
    total_bookings DESC;

-- 6) Analyzing Customer Behavior: Repeated vs. New Guests
[cite_start]-- This query compares the behavior of repeated guests (is_repeated_guest = 1) versus new guests (is_repeated_guest = 0), calculating total bookings, average booking changes, and average daily rate in the 2020 dataset[cite: 1].
SELECT
    is_repeated_guest,
    COUNT(*) AS total_bookings,
    AVG(booking_changes) AS average_booking_changes,
    AVG(adr) AS average_daily_rate
FROM
    [dbo].['2020$']
GROUP BY
    is_repeated_guest;

-- 7) Calculate the year-over-year growth rate for average daily rate (ADR)
[cite_start]-- This query combines data from multiple years and calculates the year-over-year growth rate for the average daily rate (ADR) using the LAG window function[cite: 1].
WITH hotels AS (
    SELECT * FROM [dbo].['2018$']
    UNION
    SELECT * FROM [dbo].['2019$']
    UNION
    SELECT * FROM [dbo].['2020$']
),
YearlyADR AS (
    SELECT
        arrival_date_year,
        AVG(adr) AS avg_adr
    FROM
        hotels
    GROUP BY
        arrival_date_year
)
SELECT
    arrival_date_year,
    avg_adr,
    (avg_adr - LAG(avg_adr, 1, avg_adr) OVER (ORDER BY arrival_date_year)) / LAG(avg_adr, 1, avg_adr) OVER (ORDER BY arrival_date_year) AS yoy_growth_rate
FROM
    YearlyADR;

-- 8) Analyze the impact of lead time on cancellation rates
[cite_start]-- This query categorizes bookings by lead time and calculates the cancellation rate for each category[cite: 1].
SELECT
    CASE
        WHEN lead_time <= 7 THEN '1 Week or Less'
        WHEN lead_time > 7 AND lead_time <= 30 THEN '1 Month or Less'
        WHEN lead_time > 30 AND lead_time <= 90 THEN '3 Months or Less'
        ELSE 'More than 3 Months'
    END AS lead_time_category,
    COUNT(is_canceled) AS total_bookings,
    SUM(is_canceled) AS total_cancellations,
    CAST(SUM(is_canceled) AS FLOAT) / COUNT(is_canceled) AS cancellation_rate
FROM
    hotels
GROUP BY
    CASE
        WHEN lead_time <= 7 THEN '1 Week or Less'
        WHEN lead_time > 7 AND lead_time <= 30 THEN '1 Month or Less'
        WHEN lead_time > 30 AND lead_time <= 90 THEN '3 Months or Less'
        ELSE 'More than 3 Months'
    END
ORDER BY
    cancellation_rate DESC;

-- 9) Find the hotel with the highest revenue per guest
[cite_start]-- This query combines data from all years to calculate the total revenue and total guests, then determines the revenue per guest for each hotel[cite: 1].
WITH hotels AS (
    SELECT * FROM [dbo].['2018$']
    UNION
    SELECT * FROM [dbo].['2019$']
    UNION
    SELECT * FROM [dbo].['2020$']
)
SELECT
    hotel,
    SUM(adr) AS total_revenue,
    SUM(adults + children + babies) AS total_guests,
    SUM(adr) / SUM(adults + children + babies) AS revenue_per_guest
FROM
    hotels
GROUP BY
    hotel
ORDER BY
    revenue_per_guest DESC;

-- 10) Creating a Non-Clustered Index for Analysis
[cite_start]-- This statement creates a non-clustered index on the 'market_segment', 'country', and 'is_canceled' columns to optimize query performance for common analysis tasks on the 2019 data[cite: 1].
CREATE NONCLUSTERED INDEX IX_MarketSegment_Country_IsCanceled
ON dbo.['2019$'] (market_segment, country, is_canceled);

-- 11) A View for Market Segment Performance
[cite_start]-- This section creates a view to simplify a complex query involving multiple joins[cite: 1]. [cite_start]The view joins the 2019 booking data with market segment and meal cost tables[cite: 1].
CREATE VIEW BookingPerformance AS
SELECT
    T1.*,
    T2.Discount,
    T3.Cost AS meal_cost
FROM
    [dbo].['2019$'] AS T1
LEFT JOIN
    dbo.market_segment$ AS T2 ON T1.market_segment = T2.market_segment
LEFT JOIN
    dbo.meal_cost$ AS T3 ON T1.meal = T3.meal;

[cite_start]-- This query then uses the created view to calculate the average total cost for each market segment[cite: 1].
SELECT
    market_segment,
    AVG(adr + meal_cost) AS average_total_cost
FROM
    BookingPerformance
GROUP BY
    market_segment
ORDER BY
    average_total_cost DESC;

-- 12) Find the Top 3 Bookings by ADR for Each Market Segment (Row_number())
[cite_start]-- This query uses the ROW_NUMBER() window function to rank bookings by Average Daily Rate (ADR) within each market segment and select the top 3[cite: 1].
WITH RankedBookings AS (
    SELECT
        market_segment,
        adr,
        ROW_NUMBER() OVER (PARTITION BY market_segment ORDER BY adr DESC) as rn
    FROM
        dbo.['2019$']
)
SELECT
    market_segment,
    adr,
    rn
FROM
    RankedBookings
WHERE
    rn <= 3;

-- 13) Rank Market Segments by Average Daily Rate (ADR) (Dense_rank())
[cite_start]-- This query uses the DENSE_RANK() window function to rank each market segment based on its average ADR[cite: 1].
WITH SegmentRanks AS (
    SELECT
        market_segment,
        AVG(adr) as avg_adr,
        DENSE_RANK() OVER (ORDER BY AVG(adr) DESC) as adr_rank
    FROM
        dbo.['2020$']
    GROUP BY
        market_segment
)
SELECT
    market_segment,
    avg_adr,
    adr_rank
FROM
    SegmentRanks
ORDER BY
    adr_rank;

-- 14) Calculating Total Cost (Functions)
[cite_start]-- This section defines a user-defined function to calculate the total cost of a booking, including the ADR and meal cost[cite: 1].
CREATE FUNCTION dbo.CalculateTotalCost (@adr FLOAT, @meal VARCHAR(255))
RETURNS FLOAT
AS
BEGIN
    DECLARE @meal_cost FLOAT;

    SELECT @meal_cost = Cost
    FROM dbo.meal_cost$
    WHERE meal = @meal;

    RETURN @adr + ISNULL(@meal_cost, 0);
END;

[cite_start]-- This query then demonstrates how to use the function to calculate the total cost for a booking[cite: 1].
SELECT
    arrival_date_year,
    adr,
    meal,
    dbo.CalculateTotalCost(119.0, 'BB') AS total_cost
FROM
    [dbo].['2019$'];

-- 15) Handling Null Values
-- This section provides examples of different ways to handle NULL values in a dataset.

[cite_start]-- Replacing Nulls with a Default Value using ISNULL() [cite: 1]
SELECT
    hotel,
    ISNULL(company, 'Unknown') AS company_name,
    ISNULL(agent, 0) AS agent_id
FROM [dbo].['2019$'];

[cite_start]-- Replacing Nulls with COALESCE() [cite: 1]
SELECT
    hotel,
    COALESCE(company, 'No Company') AS company_info
FROM dbo.['2019$'];

[cite_start]-- Excluding Null Values [cite: 1]
SELECT
    market_segment,
    AVG(adr) AS average_daily_rate
FROM dbo.['2019$']
WHERE adr IS NOT NULL
GROUP BY market_segment;

[cite_start]-- Using Aggregate Functions that ignore Nulls [cite: 1]
SELECT
    COUNT(agent) AS total_agents_count,
    COUNT(*) AS total_bookings_count
FROM dbo.['2019$'];

[cite_start]-- Updating Null Values (Permanent Change) [cite: 1]
UPDATE dbo.['2019$']
SET company = 'Unknown'
WHERE company IS NULL;

-- 16) Date and Time Functions
-- This section demonstrates the use of DATEDIFF() and DATEPART() functions.

[cite_start]-- Using DATEDIFF() to find the days before cancellation[cite: 1].
SELECT
    arrival_date_year,
    arrival_date_month,
    arrival_date_day_of_month,
    reservation_status_date,
    DATEDIFF(day, CONVERT(date, CONCAT(arrival_date_year, '-', arrival_date_month, '-', arrival_date_day_of_month)), reservation_status_date) AS days_before_cancellation
FROM dbo.['2018$']
WHERE is_canceled = 1;

[cite_start]-- Using DATEPART() to count cancellations by week[cite: 1].
SELECT
    DATEPART(week, reservation_status_date) AS cancellation_week,
    COUNT(*) AS total_cancellations
FROM dbo.['2019$']
WHERE is_canceled = 1
GROUP BY DATEPART(week, reservation_status_date)
ORDER BY cancellation_week;

-- 17) String Functions
-- This section shows examples of using various string functions.

[cite_start]-- Using LEFT() to extract a substring[cite: 1].
SELECT
    market_segment,
    LEFT(market_segment, 5) AS first_five_chars
FROM dbo.['2020$'];

[cite_start]-- Using TRIM() to remove leading/trailing spaces[cite: 1].
SELECT
    TRIM(market_segment) AS cleaned_market_segment
FROM dbo.['2020$'];

[cite_start]-- Using REPLACE() to substitute a string[cite: 1].
SELECT
    REPLACE(hotel, 'Hotel', 'Inn') AS modified_hotel_name
FROM dbo.['2018$'];

-- 18) To find specific text within your database tables
-- This section provides examples of using the LIKE operator for text searches.

[cite_start]-- Case-Insensitive Search [cite: 1]
SELECT
    *
FROM
    [dbo].['2018$']
WHERE
    LOWER(market_segment) LIKE '%groups%';

[cite_start]-- Advanced Search with Multiple Conditions [cite: 1]
SELECT
    *
FROM
    dbo.['2019$']
WHERE
    arrival_date_year = 2019 AND (market_segment LIKE '%Corporate%' OR market_segment LIKE '%Groups%');