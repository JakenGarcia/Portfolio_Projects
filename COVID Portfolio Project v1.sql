SELECT 
	*
FROM
	Covid_Portfolio_Project..covid_deaths
	WHERE continent is not null
	ORDER BY 3,4

--SELECT
	--*
--FROM
	--Covid_Portfolio_Project..covid_vaccinations$

-- Select data to be used

SELECT	
	Location, 
	date, 
	total_cases, 
	new_cases,
	total_deaths, 
	total_deaths, 
	population
FROM
	Covid_Portfolio_Project..covid_deaths
WHERE continent is not null
ORDER BY
	Location, 
	date

-- Looking at Total Cases vs Total Deaths. What's the death rate per registered case? 
-- Shows death rate over time in the United States, not selecting for any other factors (like age). 
-- From the start of the outbreak until January 3rd, the percentage of people who have died in the U.S. after contracting covid is around 1.48%. 
SELECT	
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate
FROM
	Covid_Portfolio_Project..covid_deaths
WHERE 
	Location = 'United States'
ORDER BY
	Location, 
	date


-- Looking at Total Cases vs Population
-- What percentage of population has tested positive for Covid (Doesn't include actual covid positivity rate, as not everyone who has had covid has been tested.)
--	Almost 17 percent of the population, as of January 3rd 22 has contracted Covid
-- Doesn't factor in people that have tested positive twice. If total cases include people who have tested positive for covid twice, data could be slightly skewed. 
SELECT	
	Location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 as covid_percentage
FROM
	Covid_Portfolio_Project..covid_deaths
WHERE 
	Location = 'United States'
ORDER BY
	Location, 
	date


-- Looking at Countries with highest infection rate compared to population 
-- Not factoring in the amount of tests actually given. Could be undercounting countries that had high rates of infection but that didn't test at high rates. 

SELECT	
	Location, 
	Population, 
	MAX(total_cases) as max_infection_count, 
	MAX((total_cases/population))*100 as percent_tested_positive
FROM
	Covid_Portfolio_Project..covid_deaths
WHERE continent is not null
GROUP BY
	Location,
	Population
ORDER BY
	4 desc

-- Trying to figure out the countries with most covid deaths
-- total_deaths is registered as an nvarchar data type so it has to be cast as an int. Later on I could change the data type myself, but for now casting works as a temporary solution

-- TOTAL DEATHS BY CONTINENT
-- For whatever reason, this database has high, middle, and lower income as locations. I had to filter those out. 
SELECT
	Location,
	MAX(CAST(total_deaths as int)) as total_death_count
FROM
	covid_deaths
WHERE 
	continent is null AND
	location NOT LIKE '%income%'
GROUP BY 
	Location
ORDER BY 
	total_death_count desc

-- GLOBAL NUMBERS: total cases, deaths, and death percentage 

SELECT 
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as int)) as total_deaths,
	(SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as Death_percentage
FROM
	covid_deaths
WHERE
	continent IS NOT NULL AND
	location NOT LIKE '%income%'
order by 1,2
	
-- Joining my vaccination table to my deaths table 
-- Looking at total vaccinations vs population
SELECT 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
		ORDER BY dea.location,
			dea.Date) as Rolling_amt_vaxxed
FROM
	Covid_Portfolio_Project..covid_deaths dea
JOIN
	Covid_Portfolio_Project..covid_vaccinations vac
	ON
	dea.location = vac.location AND
	dea.date = vac.date
WHERE 
	dea.continent is NOT NULL AND
	dea.continent NOT LIKE '%income%'
ORDER BY
	2, 3

--USE CTE

With PopvsVac 
(
	Continent, 
	Location, 
	Date, 
	Population, 
	New_Vaccinations, 
	Rolling_amt_vaxxed
)
as
(
SELECT 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
		ORDER BY dea.location,
			dea.Date) as Rolling_amt_vaxxed
FROM
	Covid_Portfolio_Project..covid_deaths dea
JOIN
	Covid_Portfolio_Project..covid_vaccinations vac
	ON
	dea.location = vac.location AND
	dea.date = vac.date
WHERE 
	dea.continent is NOT NULL AND
	dea.continent NOT LIKE '%income%'
)
Select 
	*,
	(Rolling_amt_vaxxed/population)*100 as percent_vaxxed
FROM
	PopvsVac

-- TEMP TABLE
DROP Table IF EXISTS #Percent_Population_Vaccinated
CREATE Table #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_amt_vaxxed numeric
)

INSERT INTO #Percent_population_vaccinated
SELECT 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
		ORDER BY dea.location,
			dea.Date) as Rolling_amt_vaxxed
FROM
	Covid_Portfolio_Project..covid_deaths dea
JOIN
	Covid_Portfolio_Project..covid_vaccinations vac
	ON
	dea.location = vac.location AND
	dea.date = vac.date
WHERE 
	dea.continent is NOT NULL AND
	dea.continent NOT LIKE '%income%'

Select 
	*,
	(Rolling_amt_vaxxed/population)*100 as percent_vaxxed
	-- Percent vaxxed isn't a great number because it's not taking into account the number of vaccines per person. This is why number goes over 100% at times. 
FROM
	#Percent_population_vaccinated


-- Creating View for later visualizations
 CREATE View PercentPopulationVaccinated as
SELECT 
	dea.continent, 
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location
		ORDER BY dea.location,
			dea.Date) as Rolling_amt_vaxxed
FROM
	Covid_Portfolio_Project..covid_deaths dea
JOIN
	Covid_Portfolio_Project..covid_vaccinations vac
	ON
	dea.location = vac.location AND
	dea.date = vac.date
WHERE 
	dea.continent is NOT NULL AND
	dea.continent NOT LIKE '%income%'

