boro <- c(
  "Manhattan" = "manhattan",
  "Brooklyn" = "brooklyn",
  "Bronx" = "bronx",
  "Queens" = "queens",
  "Staten Island" = "statenisland"
)
myUI <- fluidPage(
  #Main css file
  includeCSS("www/landing-page.css"),
  title = "NYC Restaurants Landing Page",
  
  navbarPage(
    title = "NYC Restaurants", id = "navbarID",
    
    tabPanel("Main", 
      value = "main",
      fluidRow(
        class = "landing-page",
        column(12, class="borough-dropdown",align="center", 
        uiOutput(
        outputId = ("main"))),
        actionButton("interactiveMap", "Find a restaurant")
      ),
      fluidRow(
        class = "section-2",
        column(12, class="wn",align="center", 
               uiOutput(
                 outputId = ("ma")))
      )
    ),
    tabPanel("Restaurant",
      value = "restaurant",
      dashboardPage(
        dashboardHeader(disable = TRUE),
        dashboardSidebar( 
          sidebarMenu(id = "menu", sidebarMenuOutput("menu"))
        ),
        dashboardBody(
          tabItems
          (
            tabItem
            (tabName = "restaurant",
              fluidRow(
                column(12, class="nyc-logo",  img(src="logo-nyc-open-data.png", height = "auto", width="180px"))
              ),
              fluidRow(
                
                column(12, leafletOutput("businessMap")),
                column(6,h2())
              ),
              fluidRow(
                uiOutput(outputId = "grade")
              ),
              fluidRow(
                column(3,offset = 1,class="cwidgets", plotlyOutput("histogram")),
                column(3,class="cwidgets",plotlyOutput("plot1")),
                column(4,class="cwidgets",  dataTableOutput(outputId = "violations"))
              )
            ),
            tabItem(tabName = "table",
                    dataTableOutput(outputId = "table"))
    
          )
        )
      )
    ),
    
    tabPanel("Interactive map",
       value = "interactivemap",
       div(class="outer",
           
           tags$head(
             # Include our custom CSS
             includeCSS("www/landing-page.css")
             #includeScript("gomap.js")
           ),
           
           # If not using custom CSS, set height of leafletOutput to a number instead of percent
           leafletOutput("map", width="100%", height="100%"),
           
           # Shiny versions prior to 0.11 should use class = "modal" instead.
           absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                         draggable = TRUE, top = 60, left = "auto", right =  20, bottom = "auto",
                         width = 330, height = "auto",
                         
                         h2("Filter by borough"),
                         
                         selectInput("boro", "Borough", boro),
                         img(src="yelp.png", height = "120px", width="240px")
           )
       )
    )
  )
)