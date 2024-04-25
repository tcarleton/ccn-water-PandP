# Description: This file produces Figure 3a. To do so, it also calculates the
# largest bilateral virtual water flows and adds them to the map as linestrings.

# CLEAN VIRTUAL WATER DATA -----------------------------------------------------

# load merged virtual water trade data
grace_virtwflows <- read_dta("data/intermediate/grace_merged/grace_virtwflows.dta")

# load long virtual water data
virtual_water <- read_csv("data/intermediate/trade/virtualwater_baseline.csv")

# load country-specific virtual water imports/exports
water_trade <- read_csv("data/intermediate/trade/water_trade.csv")

# aggregate to the country level
grace_virtwflows_cntry <- grace_virtwflows %>% 
  group_by(country_code) %>% 
  summarize(delta_tws = weighted.mean(delta_wd_cm_yr,areahec),
            rain_cm_yr = weighted.mean(rain_cm_yr,areahec),
            neg_gwater_depth = weighted.mean(neg_gwater_depth,areahec),
            surface_water = weighted.mean(surface_water,areahec)) %>% 
  left_join(water_trade,by=c("country_code"="iso"))

# CALCULATE LARGEST BILATERAL FLOWS --------------------------------------------

# merge map data with virtual water flows data
countries_virt_w_netimp <- countries_sf %>% 
  left_join(water_trade,by="iso")

# gross bilateral water flows
bil_w_flow <- virtual_water %>% 
  group_by(i_iso3,j_iso3) %>% 
  summarize(virtualwater=sum(virtualwater_bluegreen,na.rm=T)) %>% 
  ungroup() %>% 
  filter(i_iso3!=j_iso3)

# choose largest flows
largest_flows <- bil_w_flow %>% 
  mutate(virtualwater_km3=virtualwater/10^9) %>% 
  arrange(desc(virtualwater_km3)) %>% 
  head(5) %>% 
  mutate(id=row_number())

# MAKE LINESTRING SF OBJECTS ---------------------------------------------------

# dataset of centroids between countries
centroids <- countries_virt_w_netimp %>%
  st_centroid() %>%
  filter(iso %in% c(largest_flows$i_iso3,largest_flows$j_iso3)) %>%
  filter(!(iso=="NLD" & name!="Netherlands")) %>% # discard carribbean Netherlands
  st_transform(crs=4326) %>%
  dplyr::select(iso)

start_coords <- largest_flows %>%
  dplyr::select(i_iso3) %>%
  left_join(centroids,by=c("i_iso3"="iso")) %>%
  st_as_sf() %>%
  st_coordinates() %>%
  as.data.frame() %>% 
  mutate(id=row_number()) %>% 
  rename(start_lon=X,
         start_lat=Y) %>% 
  left_join(dplyr::select(largest_flows,id,i_iso3),by="id") %>% 
  rename(start_iso=i_iso3)

end_coords <- largest_flows %>%
  dplyr::select(j_iso3) %>%
  left_join(centroids,by=c("j_iso3"="iso")) %>%
  st_as_sf() %>%
  st_coordinates() %>%
  as.data.frame() %>% 
  mutate(id=row_number()) %>% 
  rename(end_lon=X,
         end_lat=Y) %>% 
  left_join(dplyr::select(largest_flows,id,j_iso3),by="id") %>% 
  rename(end_iso=j_iso3)

connections <- start_coords %>% 
  left_join(end_coords,by="id")

# function that makes path between two points
getGreatCircle <- function(userLL,relationLL){
  tmpCircle = greatCircle(userLL,relationLL, n=200)
  start = which.min(abs(tmpCircle[,1] - data.frame(userLL)[1,1]))
  end = which.min(abs(tmpCircle[,1] - relationLL[1]))
  greatC = tmpCircle[start:end,]
  return(greatC)
}

# make linestrings between centroids
linestrings <- data.frame(id=numeric(0))
for (i in 1:nrow(connections)){
  # extract centroid coordinates
  start <- c(connections$start_lon[i],connections$start_lat[i])
  end <- c(connections$end_lon[i],connections$end_lat[i])
  # make linestring from coordinates
  tmp_line <- getGreatCircle(start, end) %>% 
    as.data.frame() %>% 
    st_as_sf(coords=c("lon","lat"),
             crs=4326) %>% 
    summarize(do_union=F) %>% 
    st_cast("LINESTRING") %>% 
    mutate(id=i)
  # save
  linestrings <- rbind(linestrings,tmp_line)
}

# join with flow characteristics
linestrings <- linestrings %>% 
  left_join(largest_flows,by=c("id"))

# MAP --------------------------------------------------------------------------

# map arguments
col_vec = rev(hcl.colors(217,"RdYlGn"))
start_lim = -500
end_lim = 500
mid_pt = 0
title_text = bquote("Net Virtual Water Imports" ~ (km^3))

# map
map_virt_w_netimp <- countries_virt_w_netimp %>%
  ggplot() +
  geom_sf(aes(fill = as.numeric(virt_w_netimp_km3)))+ 
  geom_sf(data=linestrings,
          arrow=arrow(angle=45,
                      type="open",
                      ends = "last"),
          aes(lwd=virtualwater_km3),
          show.legend = F)+
  xlim(-14000000,16807980)+ # makes sure map is centered
  scale_fill_gradientn(colors = col_vec, 
                       na.value = "#E3E1E1",
                       limits=c(start_lim,end_lim),
                       values=rescale(c(start_lim, (mid_pt+start_lim)/2, mid_pt-0.00000000001, mid_pt, mid_pt+0.00000000001, (end_lim+mid_pt)/2, end_lim)),
                       oob=squish) +
  coord_sf(crs=st_crs(robin_proj))+
  labs(fill=title_text,
       color=bquote("Individual Water Flows" ~ (km^3)))+
  guides(fill = guide_colorbar(title.position = "top"))+
  theme(legend.position = "bottom",
        legend.direction="horizontal",
        legend.box.background = element_blank(),
        legend.title.align = 0.5,
        legend.key.size = unit(0.5, 'cm'),
        legend.key.width=unit(2,"cm"),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        plot.background = element_rect(color = 'white'),
        plot.margin = margin(0, 0, 0, 0),
        panel.background = element_blank(),
        panel.grid.major = element_blank())

ggsave(map_virt_w_netimp,
       filename="results/fig3a.png",
       height=6,
       width=12,
       units = "in")

rm(list=setdiff(ls(), keep))
