library(shiny)
library(DT)
library(bs4Dash)
library(fresh)
library(raster)
library(leaflet)
library(shinycssloaders)
library(rintrojs)

shinyUI(
  bs4DashPage(
    title = "WIO Symphony",
    # Header ####
    header = dashboardHeader(
      title = dashboardBrand(
        title = "", #tags$img(src="logo.jpg", height = '120px', width ='200px'),
        color = "info",
        href = "https://www.havochvatten.se/en/eu-and-international/international-cooperation/swam-ocean/wio-symphony---a-tool-for-ecosystem-based-marine-spatial-planning.html",
        image =  "logo.jpg"
      ),
      status = "info",
      h3("WIO Symphony", align = "center", style = "color: white; font-size: min(4vw, 50px)"),
      rightUi = uiOutput("how")
    ),
    dark = NULL, 
    # Sidebar ####
    sidebar = dashboardSidebar(
      disable = T
    ),
    # Controlbar ####
    controlbar = NULL, #dashboardControlbar(),
    # Body ####
    body = dashboardBody(
      introjsUI(),
      
      fluidPage(
        tags$style(type = "text/css", "#layerMap {height: calc(100vh - 250px) !important;}"),  # Storleken på kartan
        tags$head(tags$link(rel="shortcut icon", href="logo.jpg")),
        tags$head(tags$style(HTML(CSS))),
        fluidRow(
          column(
            width = 4,
            tags$style( # Fixar muspekare vi hoover över lagerlistan
              '#layerListTable {
              cursor: pointer;
              }'
            ),
            box(
              width = 12,
              title = "List of layers",
              solidHeader = T,
              status = "info",
              elevation = 3,
              selectInput(
                inputId = "themeSelect",
                label = "Select theme",
                choices = c("All layers", unique(metadata$theme)),
                selected = "All layers"
              ),
              uiOutput("subthemeUI"),
              dataTableOutput(outputId = "layerListTable")
            )
            
          ),
          column(
            width = 8,    
            box(
              id = "mapBox",
              width = 12,
              title = "Layer information",
              label = boxLabel(actionButton("addComment", 
                                            "Add comment",
                                            icon = icon("comments"),
                                            class = "btn-xs"), 
                               status = "info"),
              solidHeader = T,
              status = "info",
              elevation = 3,
              bs4Dash::tabsetPanel(
                type = "tabs",
                tabPanel(
                  title = "Overview",
                  br(),
                  fluidRow(
                    column(
                      width = 12,
                      uiOutput(outputId = "layerName"),
                      htmlOutput(outputId = "layerInfo"),
                      uiOutput(outputId = "layerBadges")
                    )
                    # column(
                    #   width = 6,
                    #   tags$head( # Fixar storleken på bilden när storleken på fönstret ändras
                    #     tags$style(
                    #       type="text/css",
                    #       "#mapThumb img {max-width: 100%; max-height: 100%; width: 100%; height: auto}"
                    #     )
                    #   ),
                    #   imageOutput(outputId = "mapThumb", width = "100%", inline = F),
                    #   textOutput("imgText")
                    # )
                  )
                ),
                tabPanel(
                  title = "Distribution map",
                  withSpinner(
                    leafletOutput(outputId = "layerMap")
                    )
                ),
                tabPanel(
                  title = "Uncertainty map",
                  leafletOutput(outputId = "layerMapUncertainty")
                ),
                tabPanel(
                  title = "Sensitivity",
                  tableOutput(outputId = "layerSensitivity")
                )
              ),
              hr(), 
              br(),
              uiOutput("commentsFromDB")
            )
          )
        )
      )
    ),
    # Footer ####
    footer = dashboardFooter()
  )
)

