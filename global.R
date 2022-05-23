library(dplyr)
library(xlsx)
library(rio)
library(htmltools)
library(htmlwidgets)
library(googlesheets4)


#files <- list.files("raster/", pattern = "\\.tif$")

sensitivity = data.frame(
  sperm_whales = c(4, 2.2, 3.8, 2.6),
  whalesharks = c(1.3, 3.8, 4.2, 1.1),
  penguins = c(1.8, 3.3, 0, 4.1),
  sharks = c(4, 2.2, 3.8, 2.6),
  trawling = c(1.3, 3.8, 4.2, 1.1),
  drifting_longline = c(1.8, 3.3, 0, 4.1),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0),
  tuna = c(0, 0, 0, 0)
)
sensitivityNames <- c("Fishing", "Shipping", "Noise", "Nutrient")

#metadata <- read.csv2("metadata/metadata_sourcesym2.csv") |> mutate(filename = files)
#names(metadata)[1] <- "layer"
# metadata <- read.xlsx("metadata/metadata_sourcesym.xlsx", sheetName = "meta")
metadata <- rio::import("metadata/metadata_sourcesym.xlsx") |> 
  arrange(layer)
#metadata <- rio::import("metadata/metadata_sourcesym3.csv")

# Google sheets for storing comments ----
gs4_auth(cache = ".secrets", email = "redisland11@gmail.com")
commentsSheet = gs4_get("https://docs.google.com/spreadsheets/d/16kbiaX8smR9N9ImIHorTDDEjr2ttp2BCIvhCU9UcNRs")

# CSS for image and metadata text
CSS <- "
p {
  line-height: 1.6; 
  font-family: Helvetica;
  text-align: justify;
  font-size: 14px;
}

.Rlogo {
  width: 100%;
  height: auto;
  margin-left: 20px;
  max-width: calc(60vh - 250px); 
  max-height: 100%;
}

figcaption {
  margin-left: 20px;
  margin-bottom: 10px;
  font-style: italic;
  padding: 2px;
  font-size: 12px;
  text-align: left;
}
"

# How? text ----
introText <- c(
  "<p><strong> Choose layer </p></strong>
      <p>Choose a layer here to find out more information about how it was created and it's distribution</p>",
  
  "<p><strong> Overview </p></strong>
      <p>Here is the metadata of the selected layer</p>
      <p>The picture shows a small overview of the distribution</p>",
  
  "<p><strong> Distribution map </p></strong>
      <p>Here is a more detailed map of the layer distribution where you can move around and zoom in and out</p>",
  
  "<p><strong> Uncertainty map </p></strong>
      <p>A map showing the uncertainty of the layer</p>",
  
  "<p><strong> Sensitivity </p></strong>
      <p>The Sensitivity table shows the experts' assessed sensitivity from each pressure on the selected layer if you choosed a ecosystem component.
  If you have choosed a pressure layer you can see the experts' assessed sensitivity from that layer on each ecosystem component</p>"
)
introSteps <- c(
  "body > div.wrapper > div.content-wrapper > section > div > div > div.col-sm-4 > div > div",
  "body > div.wrapper > div.content-wrapper > section > div > div > div.col-sm-8 > div > div > div.card-body > div > ul > li:nth-child(1)",
  "body > div.wrapper > div.content-wrapper > section > div > div > div.col-sm-8 > div > div > div.card-body > div > ul > li:nth-child(2)",
  "body > div.wrapper > div.content-wrapper > section > div > div > div.col-sm-8 > div > div > div.card-body > div > ul > li:nth-child(3)",
  "body > div.wrapper > div.content-wrapper > section > div > div > div.col-sm-8 > div > div > div.card-body > div > ul > li:nth-child(4)"
)

