library(shiny)
library(shinydashboard)

library(leaflet)
library(tidyverse)
library(httr)
library(dplyr)
library(RMySQL)
library(data.table)
library(Cairo)
library(plotly)
library(shiny.router)


#library(leaflet)
library(leaflet)
source('myUI.R')
source('myServer.R')

shinyApp(
  ui = myUI,
  server = myserver
)