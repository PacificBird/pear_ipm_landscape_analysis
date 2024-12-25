library(terra)
library(sf)
library(tidyverse)
library(tidyterra)
library(basemaps)
library(furrr)
  plan(multisession, workers=20) # Change if you have less than 20 threads


zonal_analysis <- function(data, orchards, buffer, width, map=FALSE) {
          data.sf = st_as_sf(data,
                             coords = c('x','y'),
                             crs = 26911)
          raster = rasterize(orchards,
                           rast(
                            data.sf |> vect() |> buffer(1000),
                            resolution = c(30,30)
                           ),
                           field = 'conv',
                           background = 0)
          if (map) {
            base <- basemap_raster(raster,
                                   map_service = 'osm',
                                   map_type = 'streets')
            base_terra <- rast(base) |> project('epsg:26911', method='cubic')
            ggplot() +
              geom_spatraster_rgb(data = base_terra) +
              geom_spatraster(data = raster, show.legend = FALSE) +
              scale_fill_gradient(low = NA, high = '#3268a8') +
              geom_spatvector(data = st_buffer(data.sf,dist=1000) |>
                                     vect() |>
                                     aggregate(dissolve = TRUE),
                              fill = NA,
                              color='black') +
              geom_spatvector(data = vect(data.sf), color='black', size=0.5) ->
              p
            ggplotly(p) # make sure browser is set with `options(browser = _)`
          }
          # Using SF buffer and not Terra because it can be used with furrr
          # Terra spatvector/raster datatypes use foreign pointers so they can't
          buffer |>
            future_map(~{
                st_buffer(data.sf, dist = .) |>
                st_boundary() |>
                st_buffer(dist = width/2)
              },
              .options = furrr_options(seed = 123)
            ) |>
            map(~{
              zonal(raster,
                    vect(.),
                    fun = mean,
                    as.polygons = TRUE)
            })
}
