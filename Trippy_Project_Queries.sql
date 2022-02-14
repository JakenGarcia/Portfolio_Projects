/* PROCESS DATA 

PRIMARY TASKS: 

- Transform data so it can be utilized effectively
	- Join all tables into one so that data from December 2020- November 2021 can be analyzed simultaneously
- Check the data for errors and clean up any issues
	- Check for missing data
	- Check for duplicates 
- Continue transforming data
	- Create a ride_length column to determine different trip times
	- Create a day_of_week column to determine which weekday a trip was taken
	- Create a month column to determine which month a trip was taken

 */

-- Some of the datatypes are float when they should be nvarchar(255). 

ALTER TABLE [Trippy_Data].[dbo].['202012-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255);

ALTER TABLE [Trippy_Data].[dbo].['202101-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255);

ALTER TABLE [Trippy_Data].[dbo].['202102-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202103-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202104-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202105-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202106-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202107-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202108-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202109-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202110-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202111-divvy-tripdata$']
ALTER COLUMN [start_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202104-divvy-tripdata$']
ALTER COLUMN [end_station_id] nvarchar(255)

ALTER TABLE [Trippy_Data].[dbo].['202107-divvy-tripdata$']
ALTER COLUMN [end_station_id] nvarchar(255)
-- Combine all tables into one long table 
SELECT* FROM [Trippy_Data].[dbo].['202012-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202101-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202102-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202103-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202104-divvy-tripdata$']
UNION ALL 
SELECT * FROM [Trippy_Data].[dbo].['202105-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202106-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202107-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202108-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202109-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202110-divvy-tripdata$']
UNION ALL
SELECT * FROM [Trippy_Data].[dbo].['202111-divvy-tripdata$']

-- Creating a new table with all the values from tables using a subquery

SELECT 
	a.*
INTO
	[total-divvy-tripdata]
FROM
	(SELECT* FROM [Trippy_Data].[dbo].['202012-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202101-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202102-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202103-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202104-divvy-tripdata$']
	UNION ALL 
	SELECT * FROM [Trippy_Data].[dbo].['202105-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202106-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202107-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202108-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202109-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202110-divvy-tripdata$']
	UNION ALL
	SELECT * FROM [Trippy_Data].[dbo].['202111-divvy-tripdata$']) a
-- DATA CLEANING
--CHECK FOR MISSING DATA AND FILL IN WHERE NECESSARY
SELECT
	start_station_name,
	start_station_id
FROM
	[total-divvy-tripdata]
WHERE
	start_station_name IS NOT NULL AND
	start_station_id IS NULL

SELECT
	start_station_name,
	start_station_id
FROM
	[total-divvy-tripdata]
WHERE
	start_station_name IS NULL AND
	start_station_id IS NOT NULL

SELECT
	end_station_name,
	end_station_id
FROM
	[total-divvy-tripdata]
WHERE
	end_station_name IS NOT NULL AND
	end_station_id IS NULL

SELECT
	end_station_name,
	end_station_id
FROM
	[total-divvy-tripdata]
WHERE
	end_station_name IS NULL AND
	end_station_id IS NOT NULL

-- Some station_ids are missing. I need to populate station_id where start_station_name or end_station_name is filled
--I'm going to use a CTE to join onto the original dataset and populate the empty station_ids with the filled ids from the same station locations. 
WITH station_names (start_station_name, start_station_id) as
(
SELECT DISTINCT
	start_station_name,
	start_station_id
FROM
[Trippy_Data].[dbo].[total-divvy-tripdata]
WHERE
	start_station_id IS NOT NULL)
/* 
Select
	a.start_station_id,
	a.start_station_name,
	c.start_station_id,
	c.start_station_name
*/
UPDATE a 
SET a.start_station_id = ISNULL(a.start_station_id,c.start_station_id)
FROM
	[Trippy_Data].[dbo].[total-divvy-tripdata] a
RIGHT JOIN
	station_names c
ON
	a.start_station_name = c.start_station_name 
WHERE
	a.start_station_id IS NULL 
-----------------------------------

WITH station_names (start_station_name, start_station_id) as
(
SELECT DISTINCT
	start_station_name,
	start_station_id
FROM
[Trippy_Data].[dbo].[total-divvy-tripdata]
WHERE
	start_station_id IS NOT NULL AND
	start_station_name is NOT NULL)

UPDATE a
SET a.start_station_name = ISNULL(a.start_station_name,c.start_station_name)
FROM
	[Trippy_Data].[dbo].[total-divvy-tripdata] c
JOIN
	station_names a
ON
	a.start_station_id = c.start_station_id 
WHERE
	a.start_station_name IS NULL 
------------------------------
WITH station_names (end_station_name, end_station_id) as
(
SELECT DISTINCT
	end_station_name,
	end_station_id
FROM
[Trippy_Data].[dbo].[total-divvy-tripdata]
WHERE
	end_station_id IS NOT NULL AND
	end_station_name is NOT NULL)

/* SELECT
	a.end_station_id,
	a.end_station_name,
	c.end_station_id,
	c.end_station_name
*/
UPDATE a 
SET a.end_station_id = ISNULL(a.end_station_id,c.end_station_id)
FROM
	[Trippy_Data].[dbo].[total-divvy-tripdata] a
JOIN
	station_names c
ON
	a.end_station_name = c.end_station_name 
WHERE
	a.end_station_id IS NULL 
--------------------------------
	

WITH station_names (end_station_name, end_station_id) as
(
SELECT DISTINCT
	end_station_name,
	end_station_id
FROM
[Trippy_Data].[dbo].[total-divvy-tripdata]
WHERE
	end_station_name IS NOT NULL AND
	end_station_id is NOT NULL)
/*SELECT
	a.start_station_name,
	a.start_station_id,
	c.end_station_name,
	c.end_station_id
*/
UPDATE a
SET a.start_station_id = ISNULL(a.start_station_id,c.end_station_id)
FROM
	[Trippy_Data].[dbo].[total-divvy-tripdata] a
JOIN
	station_names c
ON
	a.start_station_name = c.end_station_name 
WHERE
	a.start_station_id IS NULL 
------------
SELECT
	*
FROM
	[total-divvy-tripdata]
WHERE
	start_station_name IS NOT NULL AND
	start_station_id IS NULL

SELECT
	*
FROM
	[total-divvy-tripdata]
WHERE
	start_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION' OR
	end_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION'
-- ONLY ONE station still without an ID. There are no ways to fill this ID from the database, as no corresponding station id exists in the database
-- SEARCH FOR DUPLICATES
-- By partitioning off of the starting time and location of a bike ride, I  am verifying there are no duplicate entries. 
-- It is impossible for more than one ride_id to be associated with a bike leaving from the exact same location at the exact same times
WITH RowNumCTE AS (
SELECT TOP (1000)
	*,
	ROW_NUMBER() OVER (
	PARTITION BY started_at,
	ended_at,
	start_station_name,
	end_station_name,
	start_lat,
	start_lng,
	end_lat,
	end_lng
	ORDER BY ride_id) row_num
FROM
	[total-divvy-tripdata]
)
SELECT
	*
FROM
	RowNumCTE
WHERE
	row_num > 1
-- NO DUPLICATES FOUND
-- TRANSFORM DATA
-- I'm going to add a ride_length column, a day of the week column, and a month column

SELECT TOP (1000)
	*,
	CAST(ended_at-started_at as time) as ride_length
FROM
	Trippy_Data..[total-divvy-tripdata]
ORDER BY
	ride_length 
--I'm noticing that there are entries in here that only last a second or two. These may be misleading, as a person isn't going to go on a one-second long bike ride.
-- When I get to the tableau portion, I'm going to filter out bike rides that are less than 10 seconds long. 

SELECT TOP (1000)
	*,
	DATEPART(MONTH,started_at) as month,
	DATEPART(dw,started_at) as day_of_week
FROM
	Trippy_Data..[total-divvy-tripdata]
ORDER BY 
	started_at desc
--Now I just need to insert these values into my table 

ALTER TABLE TRippy_Data..[total-divvy-tripdata]
ADD  
	ride_length time,
	month integer,
	day_of_week integer

UPDATE Trippy_Data..[total-divvy-tripdata]
SET 
	ride_length = CAST(ended_at-started_at as time),
	month = DATEPART(MONTH,started_at),
	day_of_week = DATEPART(dw,started_at)
	
SELECT TOP (1000)
	*
FROM
	Trippy_Data..[total-divvy-tripdata]

/* Cleaning and Transformation tasks performed: 
1. Alteration of datatypes so that start and end station ids were consistently nvarchar and values could be unioned successfully across tables.
2. Union of all tables from the past twelve months, starting in December of 2020 jnto a new table having all of these values. 
3. Filled in all empty station_ids where the data was appropriate to fill in. Only one station was without a station_id in the dataset. 
4. Ran a check for duplicate values. No duplicate entries found. 
5. Learned that there are several unreliable data entries- bike trips that lasted only a few seconds. 
- These will be filtered out in the tableau phase of project. 
6. Added new columns of ride_length, month, and day_of_week for future use in analysis. 