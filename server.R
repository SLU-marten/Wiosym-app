library(shiny)
library(DT)
library(raster)
library(rintrojs)
library(htmltools)
library(dplyr)
library(stringr)
library(RColorBrewer)
library(dplyr)
library(leaflet)
library(rgdal)
library(magick)

Sys.setenv(TZ='CET')
html_caption_str <- as.character(shiny::tags$b(style = "color: red", "A styled caption"))


shinyServer(function(input, output, session) {
  # GENERAL ----
  # . Defining variabels ----
  vals <- reactiveValues(
    source = "", 
    transformation = "",
    tags = list(),
    selectedRow = 1,
    commentsDB = read_sheet(commentsSheet)
  )
  meta <- reactiveValues(
    data = metadata
  )
  # . How?-button ----
  # . . Render button ----
  output$how <- renderUI({
    actionButton(
      "btn", "",
      icon("question"), 
      style="color: black; float:right; margin: 10px;vertical-align: 50px; background-color: white; border-color: black; "
    )
  })
  # . . Trigger JS ####
  observeEvent(input$btn,{
    introjs(
      session,
      options = list(
        "nextLabel"="Nästa", 
        "prevLabel"="Tillbaka", 
        "showProgress"="true",
        "overlayOpacity"=0.7,
        "steps" = data.frame(element=introSteps, intro=introText)
      )
    )
  })
  # . Comments ----
  # . . Add comment ----
  # . . . Trigger modal on click ----
  observeEvent(input$addComment,{
    showModal(modal_DB())
  })
  # . . . Render Modal ----
  modal_DB <- function(failed = FALSE) {
    modalDialog(
      fluidPage(
        fluidRow(column(width = 12, textInput("toDBName", "Name" ))),
        fluidRow(column(width = 12, textAreaInput("toDBComment", "Comment")))
      ),
      title = "Add a comment",
      size = "s",
      easyClose = T,
      footer = column(12, modalButton("Cancel"), actionButton("sendToDB","Send"))
    )
  }
  # . . . Send comment to DB ----
  observeEvent(input$sendToDB, {
    removeModal()
    comment <- tibble(Name = input$toDBName,
                      Date = Sys.Date(),
                      Time =  as.POSIXct(format(Sys.time()),tz="GMT"),
                      Layer = meta$data$layer[input$layerListTable_rows_selected],
                      Comment = input$toDBComment)
    sheet_append(commentsSheet, 
                 comment, 
                 sheet = 1)
    vals$commentsDB <- read_sheet(commentsSheet)
  })
  # . . Load comments ----
  # . . . Render comments ----
  output$commentsFromDB <- renderUI({
    req(vals$commentsDB, vals$name)
    com <- vals$commentsDB |> filter(Layer == vals$name)
    if(nrow(com)>0){
      lapply(X = 1:nrow(com), FUN = function(i) {
        userMessage(
          author = com$Name[i],
          image = "http://cdn.onlinewebfonts.com/svg/img_33516.png",
          date = com$Time[i],
          type = "received",
          com$Comment[i]
        )
      })
    }
  })
  # OVERVIEW TAB ----
  # . Layerlist ----
  # . . Theme filter ----
  # . . . Filter layer list ----
  observeEvent(input$themeSelect,{
    meta$data <- metadata
    if(input$themeSelect != "All layers"){
      meta$data <- metadata |> 
        as_tibble() |> 
        filter(theme == input$themeSelect)
    }
    vals$selectedRow <- 1
  })
  # . . Subtheme filter ----
  # . . . Render dropdown ----
  output$subthemeUI <- renderUI({
    if(input$themeSelect != "All layers"){
      filt <- metadata |> as_tibble() |> filter(theme == input$themeSelect)
      filt2 <- unique(filt$subtheme)
      choice <- c("All layers", filt2)
      selectInput(
        inputId = "subthemeSelect",
        label = "Select subtheme",
        choices = choice,
        selected = "All layers"
      )
    }
  })
  # . . . Filter layer list ----
  observeEvent(input$subthemeSelect,{
    if(input$subthemeSelect != "All layers"){
      meta$data <- metadata |> 
        as_tibble() |> 
        filter(theme == input$themeSelect,
               subtheme == input$subthemeSelect)
    }
    vals$selectedRow <- 1
  })
  # . . Layer list  ----
  # . . . Generate layer list with comments ----
  layerListFunc <- reactive({
    coms <- vals$commentsDB |>
      dplyr::select(Layer) |>
      table() |>
      as.data.frame()
    dat <- merge(
      data.frame(Var1 = meta$data$layer),
      coms, by="Var1",
      all.x=T,
      sort = T
    )
    dat2 <- paste(as.character(icon("comment", lib = "glyphicon")), dat$Freq)
    dat2[is.na(dat$Freq)] <- ""
    return(paste(dat$Var1, dat2))
  })
  # . . . Render layer list ----
  output$layerListTable <- renderDT({
    datatable(
      data = data.frame(
        Component = layerListFunc()
      ),
      rownames = F,
      escape = F,
      selection = list(
        mode = "single", 
        target="row",
        selected = isolate(vals$selectedRow)
      ),
      options = list(
        pageLength = 100,
        dom = 't', 
        searching = FALSE
      )
    )
  })
  
  # . Updating selected layer info ----
  observeEvent(input$layerListTable_rows_selected,{
    species <- input$layerListTable_rows_selected
    vals$name <- meta$data$layer[species]
    vals$source <- meta$data$source[species]
    vals$theme <- meta$data$theme[species]
    vals$subtheme <- meta$data$subtheme[species]
    vals$citation <- meta$data$citation[species]
    vals$copyright <- meta$data$copyright[species]
    vals$comments <- meta$data$comments[species]
    vals$tags <- meta$data$tags[species]
    vals$details <- meta$data$details[species]
    vals$pngPath <- paste0("Crop/", meta$data$layer[species], ".png")
    vals$sensitivity <- sensitivity[,species]
    vals$selectedRow <- species
    vals$raster <-  paste0("raster/", meta$data$filename[species])
    vals$badges <- strsplit(vals$tags, ";")[[1]][-1]
  })
  
  # . . Renders heading ----
  output$layerName <- renderUI({
    h3(str_to_title(vals$name))
  })
  # . . Renders metadata ----
  output$layerInfo <- renderUI({
    column(
      12,
      div(
      tags$img(
      class = "Rlogo",
      src = vals$pngPath,
      figcaption = "OJOJOJ"
      ),
      br(),
      tags$figcaption(paste("Distribution map of", vals$name)),
      style = "float: right;"
      ),
    p(HTML(
      paste("<b>Source:</b>", vals$source, "</br>",
            "<b>Theme:</b>", vals$theme, "</br>",
            "<b>Subtheme:</b>", vals$subtheme, "</br>",
            "<b>Citation:</b>", vals$citation, "</br>", 
            "<b>Copyright:</b>", vals$copyright, "</br>", 
            "<b>Comments:</b>", vals$comments, "</br>", 
            "<b>Details:</b>", vals$details, "</br>", 
            "<b>Tags:</b>"
      ))
    )
    )
  })
  # . . Renders tag badges ----
  output$layerBadges <- renderUI({
    # Creats a code string based on the number of tags for the selected datasource
    UI <- paste(
      "fluidRow(column(12, ", 
      paste0(
        "dashboardBadge('", 
        vals$badges, 
        "', color = 'danger')", 
        collapse = ", "), 
      "))")
    eval(parse(text = UI))
  })
  # # . . Renders small PNG ----
  # output$mapThumb <- renderImage({
  #   req(input$layerListTable_rows_selected) #
  #     # list(src = vals$pngPath, alt="OJOJ")
  #   img <- image_read(vals$pngPath)
  #   tmpfile <- img |> 
  #     image_annotate(
  #       paste0("Distribution map of ", vals$name),
  #       size = 30,
  #       color = "white",
  #       boxcolor = adjustcolor("black", alpha = 0.5), #change the alpha value for more of less transparency
  #       gravity = "southwest"
  #     ) |> 
  #     image_write(tempfile(fileext='jpg'), format = 'jpg')
  #   list(src = tmpfile)
  # 
  # }, deleteFile = F)
  
  # DISTRIBUTION MAP TAB ----
  # . . . Renders leaflet map ----
  output$layerMap <- renderLeaflet({   
    req(input$layerListTable_rows_selected)
    rast <- -raster(vals$raster) |> projectRasterForLeaflet("ngb")
    leaflet() |> 
      addTiles() |> 
      addRasterImage(rast, project = F, opacity = 0.8)
  })
  # UNCERTAINTY MAP TAB ----
  # . . . Renders leaflet map ----
  output$layerMapUncertainty <- renderLeaflet({
  })
  # SENSITIVITY TAB ----
  # . . . Renders sensitivity table ----
  output$layerSensitivity <- renderTable({
    data.frame(
      Pressure = sensitivityNames, 
      Sensitivity = vals$sensitivity
    )
  })
})
