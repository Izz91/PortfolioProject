--Select *
--From PortfolioProject..CovidDeaths
--order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

--Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contact COVID in your country
Select Location, date, total_cases, total_deaths, CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases),0)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%malaysia%'
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got COVID
Select Location, date, Population, total_cases, NULLIF (CONVERT(float, total_cases),0)/NULLIF(CONVERT(float, population),0)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%malaysia%'
order by 1,2


Select Location, date, Population, total_cases, NULLIF (CONVERT(float, total_cases),0)/NULLIF(CONVERT(float, population),0)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like '%malaysia%'
order by 1,2

-- Looking at country with highest infection rtae compared to Population
Select Location, Population, MAX(convert(float, total_cases)) as HighestInfectionCount, Max(convert(float, total_cases)/population)*100 PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like '%malaysia%'
Group by Location, Population
order by PercentPopulationInfected desc

--Showing Countries with  Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%malaysia%'
Where continent is not null AND TRIM(continent) != '' --remove the continent
Group by Location
order by TotalDeathCount desc

--LET'S BREAK THINGS BY THE CONTINENT
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%malaysia%'
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- Get the continent only
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%malaysia%'
Where iso_code in ('OWID_EUR', 'OWID_ASI', 'OWID_NAM', 'OWID_SAM', 'OWID_AFR', 'OWID_OCE')
Group by location
order by TotalDeathCount desc

-- Showing the continent with highest death count per population
Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT date, SUM(CAST(total_cases as float)) as Total_cases, -- remove the date to calculate total cases
SUM(CAST(COALESCE(total_deaths, '0') as float)) as Total_deaths,
SUM(CAST(COALESCE(total_deaths, '0') as float))/NULLIF(SUM(CAST(total_cases as float)),0)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null AND TRIM(continent) != '' --remove the continent
Group By date
order by 1,2

--Looking at Total Population vs Vaccination

Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(COALESCE(vac.new_vaccinations, '0') as float)) OVER (Partition by dea.location Order by dea.location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null AND TRIM(dea.continent) != '' --remove the continent
order by 2,3

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(COALESCE(vac.new_vaccinations, '0') as float)) OVER (Partition by dea.location Order by dea.location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null AND TRIM(dea.continent) != '' --remove the continent
order by 2,3

--Use CTE
With PopvsVac (Contnent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(COALESCE(vac.new_vaccinations, '0') as float)) OVER (Partition by dea.location Order by dea.location, 
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null AND TRIM(dea.continent) != '' --remove the continent
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- TEMP TABLE
-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population float, -- make sure you are defining the correct data type
    New_vaccinations float,
    RollingPeopleVaccinated float
);
INSERT INTO #PercentPopulationVaccinated
Select
    dea.continent,
    dea.location,
    CONVERT(DATETIME, dea.date, 103) as Date, -- Explicit conversion of date with format 103 (DD/MM/YYYY)
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, '0') AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
From
    PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL AND TRIM(dea.continent) != '';

-- You can add an ORDER BY clause here if needed

SELECT
    *,
    (RollingPeopleVaccinated / Population) * 100
FROM
    #PercentPopulationVaccinated;



-- Creating View to store data for later visualisation
Create View PercentPopulationVaccinated as
Select
    dea.continent,
    dea.location,
    CONVERT(DATETIME, dea.date, 103) as Date, -- Explicit conversion of date with format 103 (DD/MM/YYYY)
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(COALESCE(vac.new_vaccinations, '0') AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
From
    PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL AND TRIM(dea.continent) != '';
--	order by 2,3
-- You can add an ORDER BY clause here if needed


Select *
From PercentPopulationVaccinated 