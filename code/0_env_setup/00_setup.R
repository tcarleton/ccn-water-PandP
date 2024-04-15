# Description: This file downloads and loads the R packages needed to run the project.

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

# install non-installed packages
installed_libs <- libs %in% rownames(installed.packages())
if(any(installed_libs==F)){
  install.packages(libs[!installed_libs], dependencies = T)
}

# load packages
invisible(lapply(libs,
                 library,
                 character.only=T))
rm(installed_libs,libs)