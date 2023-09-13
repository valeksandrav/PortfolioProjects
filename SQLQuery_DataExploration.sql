CREATE DATABASE PortfolioProject

-- Looking at total cases vs total deaths
-- Shows likelihood of dying of you contract covid in your country
-- 0,47% death percentage by the end of pandemic 2023-05-05
SELECT location, date, total_cases, total_deaths, 
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidData
WHERE location like '%portugal%'
ORDER BY location, date

-- Looking at total cases vs population 
-- Shows what percentage of population got covid 
-- 54% of 10 million population had gotten a test and it has been confirmed
SELECT location, date, population, total_cases, 
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidData
WHERE location like '%portugal%'
ORDER BY location, date

-- Looking at countries with highest infection rate compared to population 
-- Cyprus has the highest percentage of infected population and the US has the highest number of infections
SELECT location, population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Looking at countries with highest death count per population 
-- The US death count of 1,1 million
SELECT location,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidData
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Looking at continents with highest death count per population
-- Europe death count of 2 million 
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidData
WHERE continent IS NULL
    AND location NOT LIKE '%income'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Looking at global numbers across the world per day 
-- First cases starting to be reported at 2020-01-04
SELECT date, 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths,
    CASE WHEN SUM(new_cases) = 0 THEN 0
    ELSE SUM(new_deaths) / SUM(new_cases) * 100 
    END AS DeathPercentage 
FROM PortfolioProject..CovidData
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY date

-- Looking at total cases across the world
-- 0,9% death percentage
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths,
    CASE WHEN SUM(new_cases) = 0 THEN 0
    ELSE SUM(new_deaths) / SUM(new_cases) * 100 
    END AS DeathPercentage 
FROM PortfolioProject..CovidData
WHERE continent IS NOT NULL 

-- Looking at total population vs vaccinations using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
    (SELECT continent, location, date, population, new_vaccinations,
        SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidData
    WHERE continent IS NOT NULL)
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM PopvsVac

-- Looking at total population vs vaccinations using temp table 
DROP TABLE IF EXISTS #PercentPopulationVaccionated
CREATE TABLE #PercentPopulationVaccionated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric)
INSERT INTO #PercentPopulationVaccionated
SELECT continent, location, date, population, new_vaccinations,
        SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidData
    WHERE continent IS NOT NULL
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM #PercentPopulationVaccionated

-- Creating view percent population vaccionatedto store data for later visualization 
CREATE VIEW PercentPopulationVaccionated AS 
SELECT continent, location, date, population, new_vaccinations,
        SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidData
    WHERE continent IS NOT NULL
SELECT * 
FROM PercentPopulationVaccionated
