# Description: This file loads the R packages needed to run the project and sets
# the working directory.

# all packages needed
libs <- c(
  "tidyverse",
  "haven",
  "readxl",
  "broom",
  "sf",
  "rnaturalearthdata",
  "rnaturalearth",
  "cowplot",
  "scales",
  "biscale",
  "dichromat",
  "geosphere"
)

# load packages
invisible(lapply(libs,
                 library,
                 character.only=T))
rm(libs)
