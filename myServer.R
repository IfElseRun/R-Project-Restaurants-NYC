# Server logic
#YELP API
source(file="yelp-api.R")
source(file="nyc-api.R")

myserver <- function(input, output,session) {
  
    #Router Logic
    observeEvent(getQueryString(session)$page, {
      currentQueryString <- getQueryString(session)$page # alternative: parseQueryString(session$clientData$url_search)$page
      if(is.null(input$navbarID) || !is.null(currentQueryString) && currentQueryString != input$navbarID){
        freezeReactiveValue(input, "navbarID")
        updateNavbarPage(session, "navbarID", selected = currentQueryString)
      }
    
    #restaurant page logic
    if(currentQueryString == "restaurant") {
      restaurantQueryString <- getQueryString(session)$restaurant
      zipcodeQueryString <- getQueryString(session)$zipcode
      latQueryString <- getQueryString(session)$lat
      lonQueryString <- getQueryString(session)$lon
      locationQueryString <- getQueryString(session)$location
      
      #if both restaurant and zip code exist
      if(!is.null(restaurantQueryString) && !is.null(zipcodeQueryString) && !is.null(latQueryString) && !is.null(lonQueryString) && !is.null(locationQueryString)) {
        con <- dbConnect(MySQL(),
                         user = 'user',
                         password = 'password',
                         host = 'host',
                         dbname='nyc_restaurants')
        
        
        query_individual_business <- dbGetQuery(con, paste0("SELECT * FROM nyc_restaurants.clean_data where DBA = \"", restaurantQueryString ,"\";"))
        weighed_Score <- dbGetQuery(con, paste0("SELECT  ROUND(avg(WEIGHED_SCORE),0) FROM nyc_restaurants.clean_data where DBA = \"", restaurantQueryString ,"\";"))
        critical_flag  <- dbGetQuery(con,paste0("SELECT COUNT(CRITICAL_FLAG) FROM nyc_restaurants.clean_data where CRITICAL_FLAG = 'Critical' AND DBA = \"", restaurantQueryString ,"\";"))
        non_crtical_flag <-  dbGetQuery(con,paste0("SELECT COUNT(CRITICAL_FLAG) FROM nyc_restaurants.clean_data where CRITICAL_FLAG = 'Not Critical' AND DBA = \"", restaurantQueryString ,"\";"))
        violations <- dbGetQuery(con, paste0("SELECT INSPECTION_DATE, VIOLATION_DESCRIPTION FROM nyc_restaurants.clean_data where DBA = \"", restaurantQueryString ,"\" GROUP BY VIOLATION_DESCRIPTION;"))
 
        query_individual_business_statistics <- dbGetQuery(con, paste0("CALL getRestaurantStatistics('",locationQueryString,"', '",restaurantQueryString,"');"))
        dbDisconnect(con)
        
        output$businessMap <- renderLeaflet({
          m <- leaflet() %>%
            addProviderTiles(providers$CartoDB.Positron,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>%  # Add default OpenStreetMap map tiles
            addMarkers(lng=as.numeric(lonQueryString), lat=as.numeric(latQueryString),  popup="The birthplace of R")
          m  # Print the map
          
        })
        
        output$table <- renderDataTable(query_individual_business)
        output$violations <- renderDataTable(violations)
        
        output$plot1 <- renderPlotly({
          fig <- plot_ly(
            type = "indicator",
            mode = "gauge+number",
            value = as.numeric(weighed_Score),
            title = list(text = "Weighed Score", font = list(size = 24)),
            gauge = list(
              axis = list(range = list(NULL, 100), tickwidth = 1, tickcolor = "darkblue"),
              bar = list(color = "gray"),
              bgcolor = "white",
              borderwidth = 2,
              bordercolor = "gray",
              steps = list(
                list(range = c(0, 250), color = "white"),
                list(range = c(250, 400), color = "gray")))) 
          fig <- fig %>%
            layout(
              margin = list(l=20,r=30),
              font = list(color = "gray", family = "Arial"))
          
          fig
          
        })
        
        
        # DataFrame Logic
        output$histogram <- renderPlotly({
          fig <- plot_ly(x = c("Critical", "Non Critical"), y = c(as.numeric(critical_flag),as.numeric(non_crtical_flag)), type = 'bar',marker = list(color = 'gray',
                                                                                                     line = list(color = 'gray', width = 0.5))) %>%
            layout(title = "Number of violations",
                   xaxis = list(title = 'Critical Flag',
                                zerolinecolor = 'white',
                                zerolinewidth = 0,
                                gridcolor = 'white'),
                   yaxis = list(title = 'Amount',
                                zerolinecolor = 'gray',
                                zerolinewidth = 0,
                                gridcolor = 'gray'),
                   plot_bgcolor='#ffffff')
          fig
        })
        
        output$menu <- renderMenu({
          sidebarMenu(
            menuItem("Restaurant Overview", tabName = "restaurant", icon = icon("line-chart")),
            menuItem("Data Overview", tabName = "table", icon = icon("line-chart"))
          )
        })
        
        
        output$grade<-renderUI({
          if(as.numeric(weighed_Score) >= 87) {
            img(src="a-gr.png", height = "280px", width="240px", id="grade")
          }else if(as.numeric(weighed_Score) >= 73){
            img(src="b-gr.png", height = "280px", width="240px", id="grade")
          }else{
            img(src="c-gr.png", height = "280px", width="240px", id="grade")
          }
            
        })
        output$histogra <- renderPlotly({
          fig <- plot_ly(x = c("Critical", "Non Critical"), y = c(10,20), type = 'bar',marker = list(color = 'gray',
                                                                                                     line = list(color = 'gray', width = 0.5))) %>%
            layout(title = "Number of violations",
                   xaxis = list(title = 'Flag Category',
                                zerolinecolor = 'white',
                                zerolinewidth = 0,
                                gridcolor = 'white'),
                   yaxis = list(title = 'Amount',
                                zerolinecolor = 'gray',
                                zerolinewidth = 0,
                                gridcolor = 'gray'),
                   plot_bgcolor='#ffffff')
          fig
        })
      }
    }
  }, priority = 1)
  
  observeEvent(input$navbarID, {
    currentQueryString <- getQueryString(session)$page # alternative: parseQueryString(session$clientData$url_search)$page
    pushQueryString <- paste0("?page=", input$navbarID)
    if(is.null(currentQueryString) || currentQueryString != input$navbarID){
      freezeReactiveValue(input, "navbarID")
      updateQueryString(pushQueryString, mode = "push", session)
    }
  }, priority = 0)
  
  observeEvent(input$interactiveMap, {
    updateNavbarPage(session=session,
                     inputId="navbarID",
                     selected="interactivemap")
  })
  
  
  # Create the map
  output$map <- renderLeaflet({
    if(input$boro == "manhattan") {
      location <- "Manhattan"
    }else if (input$boro == "brooklyn") {
      location <- "Brooklyn"
    }else if (input$boro == "bronx") {
      location <- "Bronx"
    }else if (input$boro == "queens") {
      location <- "Queens"
    }else if (input$boro == "statenisland") {
      location <- "Staten Island"
    }else {
      location <- "Manhattan"
    }
    
    # Call Yelp Api Function to search for businesses by borough
    results <- yelp_business_search(term = "",location = location,radius = 7000, categories = "restaurants", rating = 5.0)
    
    # Create Map
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%  # Add default OpenStreetMap map tiles%>%
      addMarkers(
        lng=unlist( results[c('longitude')] ), 
        lat= unlist( results[c('latitude')] ), 
        popup=paste(sep = "<br/>",
                    paste0("<img src='",results$image_url,"'></img>"),
                    paste0("<b><a href='?page=restaurant&restaurant=",results$name,"&zipcode=",results$zip_code,"&lat=",unlist( results[c('latitude')]),"&lon=",unlist( results[c('longitude')] ),"&location=",location,"'>",results$name,"</a></b>"),
                    results$address1,
                    results$zip_code,
                    results$city,
                    results$rating
        ))
  })

}
