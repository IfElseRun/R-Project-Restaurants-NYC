#https://dev.socrata.com/foundry/data.cityofnewyork.us/43nn-pn8j

nycod_restaurant_search <- function(dba = NULL, zipcode = NULL) {
nycod <- "https://data.cityofnewyork.us/resource/43nn-pn8j.json"

  url <- modify_url
  res <- GET(url)
  
  results <- content(res)
 
}