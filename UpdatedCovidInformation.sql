/* Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * 
From PortfolioProject..UpdatedCovidDeaths
Where continent is not null
Order by 3, 4


--Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.dbo.UpdatedCovidDeaths
Where continent is not null
Order by 1, 2


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country
Select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
From PortfolioProject..UpdatedCovidDeaths
Where location like '%states'
and continent is not null
Order by 1, 2


--Looking at Total Cases vs Population
--Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected
From PortfolioProject.dbo.UpdatedCovidDeaths
Order by 1, 2


--Countries with Highest Infection Rate compared to Population
Select Location, Population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
From PortfolioProject..UpdatedCovidDeaths
--Where location like '%states'
Group by Location, Population, date
Order by PercentPopulationInfected desc


--Countries with highest death count per population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..UpdatedCovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount desc


--Showing Continents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..UpdatedCovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

--Showing Death Percentage of Global Total Cases
Select  date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  AS Deathpercentage
From PortfolioProject..UpdatedCovidDeaths
--Where location like '%states'
Where continent is not null
Group by date
Order by 1, 2


--Total Population vs Vaccinations
--Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..UpdatedCovidDeaths dea
Join PortfolioProject..UpdatedCovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null and new_vaccinations is not null
Order by 2, 3


--USE CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..UpdatedCovidDeaths dea
Join PortfolioProject..UpdatedCovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population) * 100
From PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query
Drop table if exists #UpdatedPercentPopulationVaccinated
Create Table #UpdatedPercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #UpdatedPercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..UpdatedCovidDeaths dea
Join PortfolioProject..UpdatedCovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population) * 100
From #UpdatedPercentPopulationVaccinated


--Creating View to store data for later visualizations
Create View UpdatedPercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..UpdatedCovidDeaths dea
Join PortfolioProject..UpdatedCovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
From UpdatedPercentPopulationVaccinated
