# Description: This file produces all maps in the paper. Thus, it generates
# Figures 1, 2a, 2c, 2e, 3a, and Appendix Figures A1a, A1c, A4a and A4c.

# ENVIRONMENT SETUP ------------------------------------------------------------

# run setup script
source("code/setup.R")

# MAPPING SETUP ----------------------------------------------------------------

# functions that transforms tiles into sf objects
tile_to_sf_polygon <- function(lon, lat, width, height) {
  # corners of the tile
  xleft <- lon - width / 2
  xright <- lon + width / 2
  ybottom <- lat - height / 2
  ytop <- lat + height / 2
  
  # polygon
  polygon <- matrix(c(xleft, ybottom,
                      xright, ybottom,
                      xright, ytop,
                      xleft, ytop,
                      xleft, ybottom), 
                    ncol = 2, 
                    byrow = TRUE)
  
  # Convert to a polygon
  polygon_sf <- st_polygon(list(polygon))
  return(polygon_sf)
}

create_tile_sf_attr <- function(df_name, lonvar, latvar, widthvar, heightvar) {
  # convert each tile into a polygon and keep in a list
  polygon_list <- mapply(tile_to_sf_polygon, 
                         df_name[[lonvar]], 
                         df_name[[latvar]], 
                         df_name[[widthvar]], 
                         df_name[[heightvar]], 
                         SIMPLIFY = FALSE)
  
  # convert the list of polygons to an sf object
  polygons_sf <- st_sfc(polygon_list) %>% 
    st_set_crs('WGS84')
  
  # attribute polygon geometry to dataframe
  df_sf <- st_sf(df_name, geometry = polygons_sf)
  
  return(df_sf)
}

# robinson projection
robin_proj = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

# country polygon
countries_sf <- ne_countries(scale="medium",
                             type="map_units",
                             returnclass = "sf") %>% 
  filter(continent!="Antarctica") %>% 
  st_transform(crs=st_crs(robin_proj)) %>% 
  rename(iso=adm0_a3_us) %>% 
  dplyr::select(name,iso)

# create color palette
n_quantile=4
inferno_pal <- c(
  "1-1" = "#bb3655", # low x, low y
  "2-1" = "#994281",
  "3-1" = "#7c5496",
  "4-1" = "#737375", # high x, low y
  "1-2" = "#e9744f",
  "2-2" = "#d07388",
  "3-2" = "#b281af",
  "4-2" = "#9e9ca9",
  "1-3" = "#fdbf53",
  "2-3" = "#f7b085",
  "3-3" = "#e4afbb",
  "4-3" = "#d0c2d9",
  "1-4" = "#fdffcd", # low x, high y
  "2-4" = "#faf5be",
  "3-4" = "#fee8c1",
  "4-4" = "#f8ebee" # high x, high y
)
inferno_pal2 <- c(
  "1-1" = "#737375", # low x, low y
  "2-1" = "#7c5496",
  "3-1" = "#994281",
  "4-1" = "#bb3655", # high x, low y
  "1-2" = "#9e9ca9",
  "2-2" = "#b281af",
  "3-2" = "#d07388",
  "4-2" = "#e9744f",
  "1-3" = "#d0c2d9",
  "2-3" = "#e4afbb",
  "3-3" = "#f7b085",
  "4-3" = "#fdbf53",
  "1-4" = "#f8ebee", # low x, high y
  "2-4" = "#fee8c1",
  "3-4" = "#faf5be",
  "4-4" = "#fdffcd" # high x, high y
)

# objects to keep in memory after running each mapping script
keep = c("countries_sf","create_tile_sf_attr","inferno_pal","inferno_pal2",
         "n_quantile","robin_proj","tile_to_sf_polygon","keep")

# PRODUCE MAPS -----------------------------------------------------------------

# figure 1
source("code/2_analysis/maps/fig1.R")

# figure 2a
source("code/2_analysis/maps/fig2a.R")

# figure 2c
source("code/2_analysis/maps/fig2c.R")

# figure 2e
source("code/2_analysis/maps/fig2e.R")

# figure 3a
source("code/2_analysis/maps/fig3a.R")

# appendix figure A1a
source("code/2_analysis/maps/figA1a.R")

# appendix figure A1c
source("code/2_analysis/maps/figA1c.R")

# appendix figure A4a
source("code/2_analysis/maps/figA4a.R")

# appendix figure A4c
source("code/2_analysis/maps/figA4c.R")
