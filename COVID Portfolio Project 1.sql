SELECT *
From PortfolioProject..CovidDeaths
-- We are adding this line of code about continent not being null, because if it is null then 'location' column contains continent name rather than country name
Where continent is not null
order by 3,4

--SELECT *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows Likelihood of dying if you contract the covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Georgia%'
and continent is not null
order by 1,2


-- Looking at total cases vs Population
-- Shows what percentage of population got Covid
Select Location, date, total_cases, Population, (total_cases/Population)*100 as InfectionRatePercentage
From PortfolioProject..CovidDeaths
Where location like '%Georgia%'
and continent is not null
order by 1, 2


-- Looking at countries with highest infection rate compared to population

Select Location, MAX(total_cases) as InfectionCount, Population, MAX((total_cases/Population))*100 as InfectionRatePerecentage
From PortfolioProject..CovidDeaths
--Where location like '%Georgia%'
Group by Location, Population
order by InfectionRatePerecentage desc

-- Looking at countries with the highest death rate compared to population
-- We are also casting total_deaths, because its existing data type nvarchar was giving us incorrect results
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Georgia%'
Where continent is not null
Group by location
order by TotalDeathCount desc


-- LETS BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%Georgia%'
Where continent is not null
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

-- By date 
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPctGlobal
From PortfolioProject..CovidDeaths
-- Where location like '%Georgia%'
Where continent is not null
Group By date
order by 1,2


-- Total
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPctGlobal
From PortfolioProject..CovidDeaths
-- Where location like '%Georgia%'
Where continent is not null
--Group By date
order by 1,2



-- Looking at Total population vs vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- We are using 'table_name.date' to indicate, from which table we are pulling the information, because after join we have 2 columns containing dates.
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingVaccinatedByCountry -- Order by dea.Date creates an aggregate sum in the last Column
--, (RollingCountryVaccinated/dea.population)*100 as PctOfCountryVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- USE CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations,  RollingVaccinatedByCountry)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- We are using 'table_name.date' to indicate, from which table we are pulling the information, because after join we have 2 columns containing dates.
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingVaccinatedByCountry -- Order by dea.Date creates an aggregate sum in the last Column
--, (RollingCountryVaccinated/dea.population)*100 as PctOfCountryVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
Select *, (RollingVaccinatedByCountry/Population)*100 as RollingPctVaccinatedByCountry
From PopvsVac




-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations bigint,
RollingVaccinatedByCountry numeric,
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- We are using 'table_name.date' to indicate, from which table we are pulling the information, because after join we have 2 columns containing dates.
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingVaccinatedByCountry -- Order by dea.Date creates an aggregate sum in the last Column
--, (RollingCountryVaccinated/dea.population)*100 as PctOfCountryVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
--Order by 2,3

Select *, (RollingVaccinatedByCountry/Population)*100 as RollingPctVaccinatedByCountry
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- We are using 'table_name.date' to indicate, from which table we are pulling the information, because after join we have 2 columns containing dates.
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingVaccinatedByCountry -- Order by dea.Date creates an aggregate sum in the last Column
--, (RollingCountryVaccinated/dea.population)*100 as PctOfCountryVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3


Select *
From PercentPopulationVaccinated