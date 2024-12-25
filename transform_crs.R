library(sf)
library(dplyr)

transform_to_utm11 <- function(path) {
  read.csv(path) |>
    st_as_sf(coords = c('x','y'), crs = 4326) |>
    st_transform(26911) |>
    data.frame() |>
    mutate(x = st_coordinates(geometry)[,1],
           y = st_coordinates(geometry)[,2]) |>
    select(-geometry)
}
