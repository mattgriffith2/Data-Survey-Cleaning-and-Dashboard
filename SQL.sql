--create raw table

create table raw.survey_data (
	unique_id VARCHAR(50),
	email VARCHAR(50),
	date_taken Date,
	time_taken time,
	Browser Varchar(50),
	OS Varchar(50),
	City text,
	Country text,
	referrer text,
	time_spent time,
	current_role text,
	switched_careers VARCHAR(50),
	current_yearly_salary VARCHAR(50),
	industry text,
	fav_programming_lang text,
	Happy_wth_Salary char(10),
	Happy_wth_work_life_balance char(10),
	Happy_wth_coworkers char(10),
	Happy_wth_management char(10),
	Happy_wth_upward_mobility char (10),
	Happy_wth_Learning_new_things char (10),
	Difficulty_to_break_into_data text,
	new_job_most_important_thing text,
	Sex text,
	Current_Age char(10),
	Country_lived_In text,
	Education_level VARCHAR(50),
	Ethnicity Text
	)
	;

--import data from csv
bulk insert raw.survey_data 
	from 'C:\Users\mattg\Downloads\Power BI - Final Project.csv'
	WITH (
    FORMAT = 'CSV',        -- SQL Server 2022+ supports FORMAT=CSV
    FIRSTROW = 2,          -- Skip header row
    FIELDTERMINATOR = ',', -- Column delimiter
    ROWTERMINATOR = '\n',  -- Row delimiter
    TABLOCK                -- Improves performance
);


--create clean table
select *
INTO clean.survey_data
FROM raw.survey_data

/* Start cleaning table */

-- remove the k in current_yearly_salary
Update clean.survey_data
set current_yearly_salary = Replace(current_yearly_salary,'k','000')
where current_yearly_salary = current_yearly_salary


--removing extra 0s in time_taken
ALTER TABLE clean.survey_data
ALTER COLUMN time_taken time(0);

--removing extra 0s in time_spent
ALTER TABLE clean.survey_data
ALTER COLUMN time_spent time(0);

--Break out repeated measures - create a new table for all of the happyness categories

Create table clean.Happiness (
	unique_id varchar(50),
	happiness_category text,
	happieness_score int
	)
	;

	insert into clean.happiness (unique_id, happiness_category, happieness_score)
	
			select unique_id, Happiness_category, hapiness_rating 
			from clean.survey_data
			UNPIVOT ( hapiness_rating for happiness_category in (happy_wth_work_life_balance,
			happy_wth_coworkers,
			happy_wth_management,
			happy_wth_upward_mobility,
			happy_wth_learning_new_things)) as unpvt

--validate table creation
select * from clean.happiness

-- Remove "Other (Please Specify) from current role
update clean.survey_data
set current_role = trim(replace(cast(current_role as varchar(50)),'Other (Please Specify):',''))
from clean.survey_data

-- Remove "Other (Please Specify) from Industry
update clean.survey_data
set industry = replace(cast(industry as varchar(50)), 'Other (Please Specify):','')
from clean.survey_data

-- Remove "Other (Please Specify) from country lived in
Update clean.survey_data
set country_lived_in = trim(replace(cast(country_lived_in as varchar(50)),'Other (Please Specify):',''))
from clean.survey_data

--Remove "Other (Please Specify) from ethnicity
Update clean.survey_data
set ethnicity = trim(replace(cast(ethnicity as varchar(50)),'Other (Please Specify):',''))
from clean.survey_data

--Remove "Other:" from fav programming language
update clean.survey_data
set fav_programming_lang = trim(replace(cast(fav_programming_lang as varchar(50)),'Other:','')) 
from clean.survey_data

--Standardize SQL related answers
update clean.survey_data
set fav_programming_lang = 'SQL'
where fav_programming_lang like '%SQL%'

--standardize people without a favorite language
update clean.survey_data
set fav_programming_lang = 'None'
where fav_programming_lang like '%none%'

update clean.survey_data
set fav_programming_lang = 'None'
where fav_programming_lang like '%dont%'

update clean.survey_data
set fav_programming_lang = 'None'
where fav_programming_lang like '%do not%'

--standardize Excel related answers
update clean.survey_data
set fav_programming_lang = 'Excel'
where fav_programming_lang like '%excel%'

-- Create a new column for average of each salary range to use for analytics
Alter Table clean.survey_data
add current_yearly_salary_average int

update clean.survey_data
set current_yearly_salary_average = 
	case
		when current_yearly_salary = '0-40000' then (0+40000)/2
		when current_yearly_salary = '106000-125000' then (106000+125000)/2
		when current_yearly_salary = '125000-150000' then (125000+150000)/2
		when current_yearly_salary = '150000-225000' then (150000+225000)/2
		when current_yearly_salary = '41000-65000' then (41000+65000)/2
		when current_yearly_salary = '66000-85000' then (66000+85000)/2
		when current_yearly_salary = '86000-105000' then (86000+105000)/2
		else 225000
		end;

--Fixing countries lived in. 

update clean.survey_data
set country_lived_in = 'Nigeria'
where country_lived_in like 'Africa (Nigeria)'

update clean.survey_data
set country_lived_in = 'Asia'
where country_lived_in like 'Aisa'

update clean.survey_data
set country_lived_in = 'Portugal'
where country_lived_in like 'Portug%'

update clean.survey_data
set country_lived_in = 'Peru'
where country_lived_in like 'Per%'

update clean.survey_data
set country_lived_in = 'Ireland'
where country_lived_in like 'Ire%'

--Categorizing answers for Most important thing in a new Job
update clean.survey_data
set new_job_most_important_thing = trim(replace(cast(new_job_most_important_thing as varchar(50)),'Other (Please Specify):',''))
from clean.survey_data

update clean.survey_data
set new_job_most_important_thing = 'Learning Opportunities'
where new_job_most_important_thing like '%Learning%'

update clean.survey_data
set new_job_most_important_thing = 'Remote Work'
where new_job_most_important_thing like '%Remote%'
