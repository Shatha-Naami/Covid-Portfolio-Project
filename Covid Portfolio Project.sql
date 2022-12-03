/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT
    *
FROM
    CovidDeaths cd
WHERE
    iso_code is NOT NULL
    

    
-- Select Data that we are going to be starting with
    
SELECT
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    CovidDeaths cd
order by
    1,
    2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
    
 SELECT
    Location,
    date,
    total_deaths,
    total_cases, 
    CAST(
        total_deaths AS DECIMAL
    ) / total_cases
    * 100 as DeathPercentage
FROM
    CovidDeaths cd
Where
    location like '%states%'
ORDER BY
    1,
    2
    
    
    
-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select
    Location,
    date,
    Population,
    total_cases,
    (
        CAST (
            total_cases AS DECIMAL
        ) / population
    )* 100 as PercentPopulationInfected
From
    CovidDeaths
Where
    location like '%states%'
ORDER BY
    1,
    2

    
-- Countries with Highest Infection Rate compared to Population
    
SELECT
    Location,
    Population,
    MAX(total_cases) as HighestInfectionCount,
    MAX((
        CAST (
            total_cases AS DECIMAL
        ) / population
    )* 100 )as PercentPopulationInfected
FROM
    CovidDeaths
GROUP BY
    Location,
    Population
ORDER BY
    PercentPopulationInfected DESC
    
    
-- Countries with Highest Death Count per Population
    
SELECT
    Location,
    MAX(CAST (total_deaths AS INT))as TotalDeathsCount
FROM
    CovidDeaths
GROUP BY
    Location
ORDER BY
    TotalDeathsCount DESC 

    
    
-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT
    continent,
    MAX(cast(total_deaths as int)) as TotalDeathCount
FROM
    CovidDeaths
Where
    continent is not null
Group by
    continent
order by
    TotalDeathCount desc
    
    
    
-- GLOBAL NUMBERS

Select
    SUM(new_cases) as total_cases,
    SUM(cast(new_deaths as int)) as total_deaths,
    SUM(cast(new_deaths as int))/ SUM(CAST(new_cases AS DECIMAL))* 100 as DeathPercentage
From
    CovidDeaths
    --Where location like '%states%'
where
    continent is not null
    --Group By date
order by
    1,
    2    
    
    
    
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


Select
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CONVERT(int, cv.new_vaccinations)) OVER (
        Partition by cd.Location
    Order by
        cd.location,
        cd.Date
    ) as RollingPeopleVaccinated
FROM
    CovidDeaths cd
Join CovidVaccinations cv 
On
    cd.location = cv.location
    And cd.date = cv.date 
    
    
where cd.continent is not null
order by
2,
3
    



-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated
)
as
(
    Select
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) OVER (
            Partition by dea.Location
        Order by
            dea.location,
            dea.Date
        ) as RollingPeopleVaccinated
       
    
From
        PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On
        dea.location = vac.location
and dea.date = vac.date
where
        dea.continent is not null
       
)


Select
    *,
    (
        RollingPeopleVaccinated / Population
    )* 100
From
    PopvsVac
    
    
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
Select
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (
        Partition by dea.Location
    Order by
        dea.location,
        dea.Date
    ) as RollingPeopleVaccinated
From
    CovidDeaths dea
Join CovidVaccinations vac
    On
    dea.location = vac.location
    and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

    
-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations
,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (
        Partition by dea.Location
    Order by
        dea.location,
        dea.Date
    ) as RollingPeopleVaccinated
From
    PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On
    dea.location = vac.location
    and dea.date = vac.date
where
    dea.continent is not null