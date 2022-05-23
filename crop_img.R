# Crops the thumbnails
library(magick)

files <- list.files("png", pattern = ".png")

for(file in files){
  img <- image_read(paste0("png/", file))
  img_crop <- image_crop(img, "800x684+97+30")
  image_write(img_crop, path = paste0("png/Crop/", file), format = "png")
}
