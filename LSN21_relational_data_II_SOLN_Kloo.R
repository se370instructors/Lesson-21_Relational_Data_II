#---SE370 AY22-2 - Lesson 21
#By: Ian Kloo
#March 2022

library(dplyr)
library(readxl)
library(purrr)
library(tidyr)
library(RSQLite)
library(DBI)


#---More complicated joins---#

#--composite keys = using multiple columns to join--#
artists <- data.frame(first = c("John", "George", "Mick", "Jimmy", 'Jason'), last = c("Lennon", "Harrison", "Jagger", "Hendricks", 'Bonham'), 
                      insturment = c("bass", "guitar", "singer", "guitar", 'Drums'))

band <- data.frame(first = c("John", "John", "George", "Mick"), last = c("Bonham","Lennon", "Harrison", "Jagger"), 
                   band = c("Led Zeppelin", "The Beatles", "The Beatles", "The Rolling Stones"))


artists
band

#need to join on both first and last name
artists %>%
  left_join(band, by = c('first','last'))

#if you just used last name, you'd get "Bonham" wrong...Jason Bonham was in Foreiner and is John Bonham's son...
#...also you get 2 first name columns
artists %>%
  left_join(band, by = "last")


#--different column names--#
#let's rewrite the `band` dataframe with new column names that don't match `artist`
band <- data.frame(FIRST_NAME = c("John", "John", "George", "Mick"), LAST_NAME = c("Bonham","Lennon", "Harrison", "Jagger"), 
                   BAND_NAME = c("Led Zeppelin", "The Beatles", "The Beatles", "The Rolling Stones"))

band

#when joining, need to use the following (strange) syntax to tell R which columns match up
artists %>%
  left_join(band, by = c("last" = "LAST_NAME", "first" = "FIRST_NAME"))

#--filtering joins...with composite keys--#

#semi_join gives you everything in x with a match in y (without combining the columns)
artists %>%
  semi_join(band, by =  c("last" = "LAST_NAME", "first" = "FIRST_NAME"))
#same as...
artists %>%
  filter(first %in% band$FIRST_NAME & last %in% band$LAST_NAME)

#anti_join does the opposite - shows all of the things in x that don't have a match in y
artists %>%
  anti_join(band, by =  c("last" = "LAST_NAME", "first" = "FIRST_NAME"))
#same as...
artists %>%
  filter(!first %in% band$FIRST_NAME & !last %in% band$LAST_NAME)


#---Relational data example: NCAA Data---#
#before we start messing with databases, let's get familiar with an NCAA basketball dataset (it is March!)

#while we're at it, let's learn how to read in and work with multi-tabbed Excel sheets

#this only reads in the first sheet...
excel_data <- read_excel('2019_ncaa_basketball.xlsx')

#...what if we want both?
filename <- '2019_ncaa_basketball.xlsx'
data <- filename %>% 
  excel_sheets() %>% 
  set_names() %>% 
  map(read_excel, path = filename)

#now we have a list containing all sheets
data[[1]]
data[[2]]

#equivalently...
sheets <- excel_sheets('2019_ncaa_basketball.xlsx')
data_list <- list()
for(i in 1:length(sheets)){
  data_list[[i]] <- read_excel('2019_ncaa_basketball.xlsx', sheet = sheets[i])
}

data_list[[1]]
data_list[[2]]

#either way, let's separate out the sheets into their own data structures:
coaches <- data$coaches
ranking <- data$ranking

#-let's say we wanted to find the average salaray of coaches in the different conferences:

#first join the ranking and coaching data together
#then do the dplyr procedure to answer the question
coaches %>%
  left_join(ranking, by = c('school' = 'TEAM')) %>%
  drop_na(CONF) %>%
  group_by(CONF) %>%
  summarize(avg_salary = mean(salary)) %>%
  arrange(-avg_salary)

#bonus: get the min and max salaraies as additional columns
coaches %>%
  left_join(ranking, by = c('school' = 'TEAM')) %>%
  drop_na(CONF) %>%
  group_by(CONF) %>%
  summarize(avg_salary = mean(salary), min_salary = min(salary), max_salary = max(salary)) %>%
  arrange(-avg_salary)


#bonus bonus: which conferences have the biggest disparity in coaching salary?
coaches %>%
  left_join(ranking, by = c('school' = 'TEAM')) %>%
  drop_na(CONF) %>%
  group_by(CONF) %>%
  summarize(salary_range = range(salary)) %>%
  arrange(-salary_range)


#---SQLite Demo---#
#operating on these tables in R is fine because they are small, but sometimes data is too big to hold in memory
#other times many people need to access the same data and storing it on everyone's machine wouldn't make sense
#example: your grades are stored in the AMS database, not on your instructor's individual computers.  if there is an update, everyone can see it.

#in R you can connect directly to a database!
#let's create our own local database that we can work with:
ncaa <- dbConnect(RSQLite::SQLite(), 'ncaa_db.sqlite')

#save some tables in the database
dbWriteTable(ncaa, 'ranking', ranking)
dbWriteTable(ncaa, 'coaches', coaches)

#retrieve the table names (useful if you don't know what all is in a DB)
dbListTables(ncaa)

#pull the data back into R:
coaches_new <- tbl(ncaa, 'coaches') %>%
  collect()

#note: `collect` is the command to bring everything into R.  you shouldn't `collect` until the very end of your analysis.
#this ensures the difficult computation gets done in the database and not on your machine.
ranking_coach <- tbl(ncaa, 'coaches') %>%
  left_join(tbl(ncaa, 'ranking'), c('school' = 'TEAM')) %>%
  collect()

#repeating our analysis from above:
tbl(ncaa, 'coaches') %>%
  left_join(tbl(ncaa, 'ranking'), by = c('school' = 'TEAM')) %>%
  filter(!is.na(CONF)) %>%
  group_by(CONF) %>%
  summarize(avg_salary = mean(salary)) %>%
  arrange(-avg_salary) %>%
  collect()

#a couple of notes:
#1. we couldn't use `drop_na` because it doesn't exist in SQL and as written, all processing is done in SQL in the DB.
#2. We had to add the filter to compensate
#3. Note warning that na.rm = TRUE is ALWAYS how SQL handles NA values

#we *could* use the exact same code if we `collect` earlier:

tbl(ncaa, 'coaches') %>%
  left_join(tbl(ncaa, 'ranking'), by = c('school' = 'TEAM')) %>%
  collect() %>%
  drop_na(CONF) %>%
  group_by(CONF) %>%
  summarize(avg_salary = mean(salary)) %>%
  arrange(-avg_salary)

#but don't do this!  you want to do as much processing as possible ON THE SERVER


#---SQLite Practice Exercise---#
db <- dbConnect(RSQLite::SQLite(), 'dallas-ois.sqlite')
dbListTables(db)

#what is the average number of cases for male and female officers where the subject is unarmed?
tbl(db, 'incidents') %>%
  filter(subject_weapon == 'Unarmed') %>%
  left_join(tbl(db, 'officers'), by = 'case_number') %>%
  group_by(gender) %>%
  summarise(gender_count = n()) %>%
  collect()

#(tricky question) count the weapons used in incidents that involved male officers and male subjects
tbl(db, 'incidents') %>%
  left_join(tbl(db, 'officers'), by = 'case_number') %>%
  left_join(tbl(db, 'subjects'), by = 'case_number') %>%
  filter(gender.x == 'M', gender.y == 'M') %>%
  group_by(subject_weapon) %>%
  summarize(weapon_count = n()) %>%
  arrange(-weapon_count) %>%
  collect()









  