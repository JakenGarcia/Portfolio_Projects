/* 
Data analysis for Chicago bike data 12/2020-11/2021
Goal: Identify how annual and casual members use cyclistic bikes differently

1. Average ride_length for members vs casual riders
2. Average ride_length by day of the week
3. Average ride_length by user by day of the week
4. Number of rides per weekday
5. Count of all rides per group 
6. Percent of rides by each month, per group
7. Preferred bike type by group 
*/
--1. Average ride_length for members vs casual users

SELECT
	AVG(DATEDIFF(minute,started_at,ended_at)) as avg_ride_length_minutes,
	member_casual as user_type
FROM
	[Trippy_Data]..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00'
GROUP By
	member_casual;
-- Average ride_length for members is shorter than casual users. This makes sense as casual users wouldn't want to spend money for something small. 

--2. Average ride_length for day of the week

SELECT
	AVG(DATEDIFF(minute,started_at,ended_at)) as avg_ride_length_minutes,
	day_of_week,
	member_casual
FROM
	[Trippy_Data]..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00'
GROUP By
	day_of_week,
	member_casual
ORDER BY
	day_of_week desc,
	avg_ride_length_minutes desc;

--Sunday is the top day of the week, followed by Saturday. Makes sense. 
--3. Avg ride length for day of the week by user type

SELECT
	AVG(DATEDIFF(minute,started_at,ended_at)) as avg_ride_length_minutes,
	day_of_week
FROM
	[Trippy_Data]..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00' AND
	member_casual = 'member'
GROUP By
	day_of_week
ORDER BY
	avg_ride_length_minutes desc;


SELECT
	AVG(DATEDIFF(minute,started_at,ended_at)) as avg_ride_length_minutes,
	day_of_week
FROM
	[Trippy_Data]..[total-divvy-tripdata]
WHERE
	ride_length > '00:01:00' AND
	member_casual = 'casual'
GROUP By
	day_of_week
ORDER BY
	avg_ride_length_minutes desc;

--Noticing a much more consistent ride length for members vs casual riders. Average ride length doesn't shift much for members. 
--This could imply that members are riding their bikes to work, as the average ride length is the same on all weekdays. 

--4. Number of rides per weekday
SELECT
	COUNT(*) as num_of_rides,
	day_of_week
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00'
GROUP BY 
	day_of_week
ORDER BY
	num_of_rides desc;

--5. Count of rides by weekday for members vs casual

SELECT
	COUNT(*) as num_of_rides,
	member_casual,
	day_of_week
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00'
GROUP BY 
	day_of_week,
	member_casual
ORDER BY
	day_of_week desc,
	num_of_rides desc;
--Casual riders ride their bikes more on the weekends; members ride their bikes more on the weekdays. 

--5.5 count of rides by month member vs casual
SELECT
	COUNT(*) as num_of_rides,
	member_casual,
	month
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	ride_length >= '00:01:00'
GROUP BY 
	month,
	member_casual
ORDER BY
	month asc,
	num_of_rides desc;


--6. Percent of rides by each month, per group--

--Percent of casual rides by month for casual users 
SELECT
	CAST(COUNT(ride_id) AS FLOAT)/(SELECT	
		COUNT(ride_id)
	FROM
		Trippy_Data..[total-divvy-tripdata]
	WHERE
			member_casual = 'casual' AND
			ride_length > '00:00:10')*100 as percent_total_rides_by_month,
	month,
	member_casual
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	member_casual = 'casual'
GROUP BY
	month,
	member_casual
ORDER BY
	month;
-- percent of total rides per month for members 
SELECT
	CAST(COUNT(ride_id) AS FLOAT)/(SELECT	
		COUNT(ride_id)
	FROM
		Trippy_Data..[total-divvy-tripdata]
	WHERE
			member_casual = 'member' AND
			ride_length > '00:00:10')*100 as percent_total_rides_by_month,
	month,
	member_casual
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	member_casual = 'member'
GROUP BY
	month,
	member_casual
ORDER BY
	month;
	
-- Members seem to use their bikes more so throughout the year than casual members do. 
-- The vast majority of casual usage comes from the summer months
SELECT
	COUNT(*) as num_of_rides,
	rideable_type,
	member_casual
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	ride_length > '00:01:00'
GROUP BY
	rideable_type,
	member_casual
ORDER BY
	rideable_type desc,
	num_of_rides desc;



 WITH cte_casual (percent_total_rides_casual,rideable_type,member_casual) AS 
 (
 SELECT
	CAST(COUNT(ride_id) AS FLOAT)/(SELECT	
		COUNT(ride_id)
	FROM
		Trippy_Data..[total-divvy-tripdata]
	WHERE
			member_casual = 'casual' AND
			ride_length > '00:01:00')*100 as percent_total_rides_casual,
	rideable_type,
	member_casual
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	member_casual = 'casual'
GROUP BY
	rideable_type,
	member_casual
--ORDER BY
	--percent_total_rides_by_type
),
cte_member (percent_total_rides_member,rideable_type,member_casual) AS 
(
 SELECT
	CAST(COUNT(ride_id) AS FLOAT)/(SELECT	
		COUNT(ride_id)
	FROM
		Trippy_Data..[total-divvy-tripdata]
	WHERE
			member_casual = 'member' AND
			ride_length > '00:01:00')*100 as percent_total_rides_member,
	rideable_type,
	member_casual
FROM
	Trippy_Data..[total-divvy-tripdata]
WHERE
	member_casual = 'member'
GROUP BY
	rideable_type,
	member_casual
--ORDER BY
	--percent_total_rides_by_type
)
SELECT
	cte_casual.percent_total_rides_casual,
	cte_member.percent_total_rides_member,
	cte_casual.rideable_type
FROM
	cte_casual 
JOIN
	cte_member
ON
	cte_casual.rideable_type  = cte_member.rideable_type;
/*
Members and casual riders both use a similar percentage of electric bikes. 
Members use far less docked bikes than casual riders, implying again that they likely using bikes to 
commute for work, as docked bikes must be docked at a station whereas other bikes can be docked at public racks,
which are likely closer to home. 
*/
