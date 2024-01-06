/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Setting Up the database

Use[PortfolioProjet1_Covid19]

Select *
From CoV_Deaths2
Where continent is not null 
order by 3,4


Select *
From CoV_Vaccs
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, collection_date, total_cases, new_cases, total_deaths, population
From CoV_Deaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows l

Select Location, Collection_Date, Total_Cases,Total_Deaths, Excess_Mortality_Cumulative_Absolute,
(total_deaths/cast(total_cases as float))*100 as DeathPercentage
From CoV_Deaths2
Where location like '%United States%' and collection_date between '2022-01-01 00:00:000' and '2022-12-31 00:00:000'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, Collection_Date, Population, Total_Cases,  (total_cases/cast(population as float))*100 as PercentPopulationInfected
From CoV_Deaths2
Where location like '%United States%' and collection_date between '2022-03-27 00:00:000' and '2022-12-31 00:00:000'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, cast(Population as float) as Population, MAX(cast(total_cases as float)) as HighestInfectionCount,  Max((cast(total_cases as float)/cast(population as float)))*100 as PercentPopulationInfected
From CoV_Deaths2
Where collection_date between '2022-03-27 00:00:000' and '2022-12-31 00:00:000'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as float)) as TotalDeathCount, MAX(cast(Excess_Mortality_Cumulative_Absolute as float)) as ExcessCumulativeMortality
From CoV_Deaths2
Where continent is not null and collection_date between '2022-03-27 00:00:000' and '2022-12-31 00:00:000'
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select Continent, MAX(cast(Total_deaths as float)) as TotalDeathCount
From CoV_Deaths2
Where continent is not null and collection_date between '2022-01-01 00:00:000' and '2022-12-31 00:00:000'
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CoV_Deaths
Where continent is not null and collection_date between '2022-01-01 00:00:000' and '2022-12-31 00:00:000'
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.collection_date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.collection_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CoV_Deaths dea
Join CoV_Vaccs vac
	On dea.location = vac.location
	and dea.collection_date = vac.collection_date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
as
(
Select dea.continent, dea.location, dea.collection_date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.collection_date) as 
RollingPeopleVaccinated
From dbo.CoV_Deaths dea
Join dbo.CoV_Vaccs vac
	On dea.location = vac.location
	and dea.collection_date = vac.collection_date
Where dea.continent is not null and dea.location not like '%income%'
)

Select*, RollingPeopleVaccinated/cast(Population as float)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.collection_date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.collection_date) as RollingPeopleVaccinated
From CoV_Deaths dea
Join CoV_Vaccs vac
	On dea.location = vac.location
	and dea.collection_date = vac.collection_date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPercentagePopulationVaccinated
From #PercentPopulationVaccinated


DROP View if exists #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.collection_date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.collection_date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CoV_Deaths dea
Join CoV_Vaccs vac
	On dea.location = vac.location
	and dea.collection_date = vac.collection_date
Where dea.continent is not null and dea.location not like '%income%' 

