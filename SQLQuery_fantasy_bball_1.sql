/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Rk]
      ,[Player]
      ,[Pos]
      ,[Age]
      ,[Tm]
      ,[G]
      ,[GS]
      ,[MP]
      ,[FG]
      ,[FGA]
      ,[FG%]
      ,[3P]
      ,[3PA]
      ,[3P%]
      ,[2P]
      ,[2PA]
      ,[2P%]
      ,[eFG%]
      ,[FT]
      ,[FTA]
      ,[FT%]
      ,[ORB]
      ,[DRB]
      ,[TRB]
      ,[AST]
      ,[STL]
      ,[BLK]
      ,[TOV]
      ,[PF]
      ,[PTS]
  FROM [NBA_Fantasy_Data].[dbo].[fantasy_raw_2021_2$]

----------DATA CLEANING---------------


  -- Data has multiple entries for players who switched teams. I need to delete the parsed out data and keep the total values for players that switched teams. 



  WITH RowNumCTE AS(
	SELECT
		*,
		ROW_NUMBER() OVER (
		PARTITION BY 
			Rk
		ORDER BY
			Rk) as tm_total
	FROM
		NBA_Fantasy_Data..fantasy_raw_2021_2$)

DELETE
FROM
RowNumCTE 
WHERE
	tm_total > 1

---Delete players where minutes played was less than 10 minutes where games played were less than 10 

DELETE
FROM
	fantasy_raw_2021_2$
WHERE
	G < 10 OR
	MP < 9

--Edit Player column to remove information after the forward slash

UPDATE
	fantasy_raw_2021_2$
SET
	Player = SUBSTRING(Player,1,CHARINDEX('\',Player)-1)

--- Delete extra data field with no information 
DELETE
FROM
NBA_Fantasy_Data..fantasy_raw_2021_2$ 
WHERE
	Player IS NULL

-- Create new column with player names broken up into first and last 

ALTER TABLE
	NBA_FANTASY_DATA..fantasy_raw_2021_2$
ADD 
	first_name text,
	last_name text

--- verifying I didn't pickup any unneeded characters 
Select
	SUBSTRING(Player,1,CHARINDEX(' ',Player)),
	len(SUBSTRING(Player,1,CHARINDEX(' ',Player))),
	SUBSTRING(Player,CHARINDEX(' ',Player)+1,LEN(Player)-1),
	Len(SUBSTRING(Player,CHARINDEX(' ',Player)+1,LEN(Player)))
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$

-- Actually updating the name columns so they have the players' names

UPDATE
	NBA_FANTASY_DATA..fantasy_raw_2021_2$
SET
	first_name = SUBSTRING(Player,1,CHARINDEX(' ',Player)),
	last_name = SUBSTRING(Player,CHARINDEX(' ',Player)+1,LEN(Player)-1)

-- Realizing I can't sort on the text datatype so I'm changing the new columns to nvarchar(255)

ALTER TABLE
	NBA_FANTASY_DATA..fantasy_raw_2021_2$
ALTER COLUMN first_name nvarchar(255);
ALTER TABLE
	NBA_FANTASY_DATA..fantasy_raw_2021_2$
ALTER COLUMN last_name nvarchar(255);


--- Turn RK column into a unique player ID and make it into a primary key 

SELECT
	ROW_NUMBER() OVER (ORDER BY last_name asc),
	*
FROM
	NBA_FANTASY_DATA..fantasy_raw_2021_2$

-- I can't use a window function unless it's in a select statement, so I'm going to make another column, use those values to replace the rank values, and then I'll drop the old column. 


WITH 
	CTE_rk (new_rk, Rk, Player) AS (
Select 
	ROW_NUMBER() OVER (ORDER BY last_name asc),
	Rk,
	Player
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$)

UPDATE
	CTE_rk
SET
	Rk = new_rk

ALTER TABLE
	NBA_Fantasy_Data..fantasy_raw_2021_2$
ALTER COLUMN 
	Rk nvarchar(255) NOT NULL;

ALTER TABLE 
	NBA_Fantasy_Data..fantasy_raw_2021_2$
ADD PRIMARY KEY (Rk);

-- also changed the name of the column to player_id

----------CREATE NEW DATA TABLE FOR ANALYSIS
DROP TABLE IF EXISTS fantasy_categories
SELECT
	Player_id,
	Player,
	Pos
INTO
	NBA_Fantasy_Data..fantasy_categories
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$
	
-- Fantasy values are how much better player x is at that category than the average player at the corresponding category 
-- Knowing a value per game is helpful, but only in the context of how much better a player is at one stat vs the field 

ALTER TABLE
	NBA_Fantasy_Data..fantasy_categories
ADD
	fant_points float,
	fant_ftm float,
	fant_3pm float,
	fant_drb float,
	fant_orb float,
	fant_ast float,
	fant_stl float,
	fant_blk float;

SELECT
	PTS/(SELECT
			AVG(pts)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$) as fant_points,
	*
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$
ORDER BY
	fant_points desc

-- Apply this same query to all fantasy categories 
-- fant_pts
UPDATE
	NBA_Fantasy_Data..fantasy_categories
SET
	NBA_Fantasy_Data..fantasy_categories.fant_pts = 
	r.PTS/(SELECT
			AVG(pts)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$)
	FROM
		NBA_Fantasy_Data..fantasy_raw_2021_2$ r
	JOIN
		NBA_Fantasy_Data..fantasy_categories c
	ON
		r.Player_id = c.Player_id


--fant_ftm
UPDATE
	NBA_Fantasy_Data..fantasy_categories
SET
	NBA_Fantasy_Data..fantasy_categories.fant_ftm = 
	r.FT/(SELECT
			AVG(FT)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$)
	FROM
		NBA_Fantasy_Data..fantasy_raw_2021_2$ r
	JOIN
		NBA_Fantasy_Data..fantasy_categories c
	ON
		r.Player_id = c.Player_id
-- 3pm,drb,orb,ast,stl,blk
UPDATE
	NBA_Fantasy_Data..fantasy_categories
SET
	NBA_Fantasy_Data..fantasy_categories.fant_3pm = 
	r.[3P]/(SELECT
			AVG([3P])
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$),

	NBA_Fantasy_Data..fantasy_categories.fant_drb = 
		r.DRB/(SELECT
				AVG(DRB)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$),
			
	NBA_Fantasy_Data..fantasy_categories.fant_orb = 
	r.ORB/(SELECT
			AVG(ORB)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$),

	NBA_Fantasy_Data..fantasy_categories.fant_ast = 
	r.AST/(SELECT
			AVG(AST)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$),

	NBA_Fantasy_Data..fantasy_categories.fant_stl = 
	r.STL/(SELECT
			AVG(STL)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$),

	NBA_Fantasy_Data..fantasy_categories.fant_blk = 
	r.BLK/(SELECT
			AVG(BLK)
		FROM
			NBA_Fantasy_Data..fantasy_raw_2021_2$)

	FROM
		NBA_Fantasy_Data..fantasy_raw_2021_2$ r
	JOIN
		NBA_Fantasy_Data..fantasy_categories c
	ON
		r.Player_id = c.Player_id
--- A total category summing up all the fantasy points of a player
ALTER TABLE NBA_Fantasy_Data..fantasy_categories
ADD	fant_tot FLOAT 

UPDATE NBA_Fantasy_Data..fantasy_categories
SET fant_tot = fant_pts + fant_ftm + fant_3pm + fant_drb + fant_orb + fant_ast + fant_stl + fant_blk

-- I need to make queries to show efficiency vs production pts, fts, and assists
-- I also need to show you if you're reading this that I know how to join tables

SELECT
	c.Player,
	c.Pos,
	c.fant_ast,
	r.ast/r.TOV as asttov_ratio
FROM
	NBA_Fantasy_Data..fantasy_categories c
JOIN
	NBA_Fantasy_Data..fantasy_raw_2021_2$ r
ON
	c.Player_id = r.Player_id
ORDER BY
	fant_ast desc

SELECT
	c.Player,
	c.Pos,
	c.fant_pts,
	r.[eFG%]
FROM
	NBA_Fantasy_Data..fantasy_categories c
JOIN
	NBA_Fantasy_Data..fantasy_raw_2021_2$ r
ON
	c.Player_id = r.Player_id
ORDER BY
	fant_pts desc

SELECT
	c.Player,
	c.Pos,
	c.fant_ftm,
	r.[FT%]
FROM
	NBA_Fantasy_Data..fantasy_categories c
JOIN
	NBA_Fantasy_Data..fantasy_raw_2021_2$ r
ON
	c.Player_id = r.Player_id
ORDER BY
	fant_ftm desc

SELECT
	*
FROM
	NBA_Fantasy_Data..fantasy_categories
ORDER BY
	fant_tot desc

SELECT
	*
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$
ORDER BY
	last_name 

---I need to have positions split into primary and secondary so I can put that in the visualization

ALTER TABLE
	NBA_Fantasy_Data..fantasy_raw_2021_2$
ADD pos_prim varchar(255),
	pos_sec varchar(255);

SELECT
	Pos,
	SUBSTRING(Pos,1,CHARINDEX('-',Pos))
FROM
	NBA_Fantasy_Data..fantasy_raw_2021_2$