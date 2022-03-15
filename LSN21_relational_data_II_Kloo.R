#---SE370 AY22-2 - Lesson 21
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


#if you just used last name, you'd get "Bonham" wrong...Jason Bonham was in Foreigner and is John Bonham's son...
#...also you get 2 first name columns



#--different column names--#
#let's rewrite the `band` dataframe with new column names that don't match `artist`
band <- data.frame(FIRST_NAME = c("John", "John", "George", "Mick"), LAST_NAME = c("Bonham","Lennon", "Harrison", "Jagger"), 
                   BAND_NAME = c("Led Zeppelin", "The Beatles", "The Beatles", "The Rolling Stones"))

band

#when joining, need to use the following (strange) syntax to tell R which columns match up



#--filtering joins...with composite keys--#

#semi_join gives you everything in x with a match in y (without combining the columns)

#same as...


#anti_join does the opposite - shows all of the things in x that don't have a match in y

#same as...



#---Relational data example: NCAA Data---#
#before we start messing with databases, let's get familiar with an NCAA basketball dataset (it is March!)

#while we're at it, let's learn how to read in and work with multi-tabbed Excel sheets

#this only reads in the first sheet...
excel_data <- read_excel('2019_ncaa_basketball.xlsx')

#...what if we want both?


#now we have a list containing all sheets


#equivalently...


#either way, let's separate out the sheets into their own data structures:


#-let's say we wanted to find the average salaray of coaches in the different conferences:

#first join the ranking and coaching data together
#then do the dplyr procedure to answer the question


#bonus: get the min and max salaraies as additional columns



#bonus bonus: which conferences have the biggest disparity in coaching salary?



#---SQLite Demo---#
#operating on these tables in R is fine because they are small, but sometimes data is too big to hold in memory
#other times many people need to access the same data and storing it on everyone's machine wouldn't make sense
#example: your grades are stored in the AMS database, not on your instructor's individual computers.  if there is an update, everyone can see it.

#in R you can connect directly to a database!
#let's create our own local database that we can work with:
ncaa <- dbConnect(RSQLite::SQLite(), 'ncaa_db.sqlite')

#save some tables in the database


#retrieve the table names (useful if you don't know what all is in a DB)


#pull the data back into R:


#note: `collect` is the command to bring everything into R.  you shouldn't `collect` until the very end of your analysis.
#this ensures the difficult computation gets done in the database and not on your machine.


#repeating our analysis from above:


#a couple of notes:
#1. we couldn't use `drop_na` because it doesn't exist in SQL and as written, all processing is done in SQL in the DB.
#2. We had to add the filter to compensate
#3. Note warning that na.rm = TRUE is ALWAYS how SQL handles NA values

#we *could* use the exact same code if we `collect` earlier:



#but don't do this!  you want to do as much processing as possible ON THE SERVER


#---SQLite Practice Exercise---#
db <- dbConnect(RSQLite::SQLite(), 'dallas-ois.sqlite')


#what is the average number of cases for male and female officers where the subject is unarmed?


#(tricky question) count the weapons used in incidents that involved male officers and male subjects










  