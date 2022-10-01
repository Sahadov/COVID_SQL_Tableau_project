-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views.

SET SESSION sql_mode = '';

-- Start with the data
Select location, date, total_cases, new_cases, total_deaths, population
From project_covid.coviddeaths
Where continent is not null 
order by location, date;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in a specific country
Select location, date, total_cases,total_deaths, round(((total_deaths/total_cases)*100),2) as death_percentage
From project_covid.coviddeaths
-- Where location='Russia'
order by location, date;


-- Total Cases vs Population in Russia
Select location, date, total_cases, population, round(((total_cases/population)*100),2) as percent_infected
From project_covid.coviddeaths
where location='Russia'
order by location, date;


-- Countries with the Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as highest_infection_count,  MAX((total_cases/population))*100 as percent_population_infected
From project_covid.coviddeaths
-- Where location = 'Russia'
Group by location, population
Order by percent_population_infected desc;


-- Countries with Highest Death Count per Population
Select location, MAX(total_deaths) as total_death_count
From project_covid.coviddeaths
-- Where location = 'Russia'
Group by location
order by total_death_count desc;

-- Showing contintents with the highest death count per population
Select continent, MAX(total_deaths) as total_death_count
From project_covid.coviddeaths
-- Where location = 'Russia'
Where continent is not null 
Group by continent
order by total_death_count desc;

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
From project_covid.coviddeaths
Where continent is not null 
-- Group By date
Order by 1,2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
With pop_vs_vac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (Partition by d.location Order by d.location, d.date) as rolling_people_vaccinated
From project_covid.coviddeaths d
Join project_covid.covidvaccinations v
On d.location = v.location And d.date = v.date
Where d.continent is not null
-- Order by 2, 3
)

Select *, round(((Rolling_People_Vaccinated/Population)*100),2) as Percent_Vaccinated
From pop_vs_vac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists project_covid.PercentPopulationVaccinated;
Create Table project_covid.PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vaccinated numeric
);

Insert into project_covid.PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (Partition by d.location Order by d.location, d.date) as rolling_people_vaccinated
From project_covid.coviddeaths d
Join project_covid.covidvaccinations v
On d.location = v.location And d.date = v.date
Where d.continent is not null;
-- order by 2,3;

Select *, (Rolling_People_Vaccinated/Population)*100 as Percent_Vaccinated
From project_covid.PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
Create View project_covid.Percent_Population_Vaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (Partition by d.location Order by d.location, d.date) as rolling_people_vaccinated
    -- (rolling_people_vaccinated/population)*100 as Percent_Vaccinated
From project_covid.coviddeaths d
Join project_covid.covidvaccinations v
On d.location = v.location And d.date = v.date
Where d.continent is not null;
