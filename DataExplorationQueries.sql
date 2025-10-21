/*
COVID-19 Data Analysis Script
It includes calculations for death percentages, infection rates, and vaccination progress.
*/

-- Preview the CovidDeaths table structure and data
SELECT *
FROM PortafolioProject.dbo.CovidDeaths
ORDER BY 3, 4;

-- Select data columns we are going to use for analysis
SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM PortafolioProject.dbo.CovidDeaths
ORDER BY 1, 2;

-- Calculate death percentage: Total deaths vs total cases for a specific location
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM PortafolioProject.dbo.CovidDeaths
WHERE total_cases IS NOT NULL 
    AND total_cases > 0 
    AND location LIKE '%nicaragua%'
ORDER BY 1, 2;

-- Calculate infection rate: Total cases vs population for a specific location
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS InfectionRate
FROM PortafolioProject.dbo.CovidDeaths
WHERE total_cases IS NOT NULL 
    AND population > 0 
    AND location LIKE '%nicaragua%'
ORDER BY 1, 2;

-- Identify countries with the highest infection rate relative to population
SELECT 
    location,  
    population,
    MAX(total_cases) AS HighestInfectionCount, 
    MAX((CAST(total_cases AS FLOAT) / NULLIF(population, 0))) * 100 AS InfectionRate
FROM PortafolioProject.dbo.CovidDeaths
WHERE total_cases IS NOT NULL 
    AND population > 0
GROUP BY location, population
ORDER BY InfectionRate DESC;

-- Show countries with the highest death count (excluding continents and aggregates)
SELECT 
    location,
    MAX(total_deaths) AS TotalDeathCount
FROM PortafolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Review death counts by all locations (including continents and aggregates)
SELECT 
    location,
    MAX(total_deaths) AS TotalDeathCount
FROM PortafolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Review death counts by continent
SELECT 
    continent,
    MAX(total_deaths) AS TotalDeathCount
FROM PortafolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Aggregate global numbers: Daily total cases, deaths, and death percentage
SELECT 
    date,  
    SUM(new_cases) AS TotalCases,
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
    (SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortafolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(new_cases) > 0 
    AND SUM(CAST(new_deaths AS INT)) > 0
ORDER BY 1, 2;

-- Calculate rolling vaccinations and demonstrate percentage vaccinated
SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortafolioProject.dbo.CovidDeaths death
JOIN PortafolioProject.dbo.CovidVaccinations vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL 
ORDER BY 2, 3;

-- Solution using CTE: Calculate percentage of population vaccinated
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS 
(
    SELECT 
        death.continent, 
        death.location, 
        death.date, 
        death.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
    FROM PortafolioProject.dbo.CovidDeaths death
    JOIN PortafolioProject.dbo.CovidVaccinations vac
        ON death.location = vac.location
        AND death.date = vac.date
    WHERE death.continent IS NOT NULL
)
SELECT 
    *, 
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM PopVsVac;


-- Solution using Temp Table: Calculate percentage of population vaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population INT,
    New_Vaccinations INT,
    RollingPeopleVaccinated INT
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortafolioProject.dbo.CovidDeaths death
JOIN PortafolioProject.dbo.CovidVaccinations vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL;

SELECT 
    *, 
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Create View for visualizations: Stores rolling vaccination data
DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortafolioProject.dbo.CovidDeaths death
JOIN PortafolioProject.dbo.CovidVaccinations vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL;

-- Query the view to verify
SELECT *
FROM PercentPopulationVaccinated;