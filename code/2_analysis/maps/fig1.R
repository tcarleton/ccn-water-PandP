# load grace data
grace <- read_dta("data/input/grace/grace.dta")

# restrict to arable land and cells with valid delta_TWS data
grace <- grace %>%
  filter(!((past_area_frac == 0 & sage_crop_area_frac == 0) |
             (is.na(past_area_frac) & is.na(sage_crop_area_frac)) |
             (is.na(past_area_frac) & sage_crop_area_frac == 0) |
             (past_area_frac == 0 & is.na(sage_crop_area_frac)))) %>%
  filter(!is.na(delta_wd_cm_yr))

# make sf object from GRACE cells
grace_sf <- create_tile_sf_attr(df_name=grace,
                                lonvar="lon",
                                latvar="lat",
                                widthvar="lonspan",
                                heightvar="latspan")

# map arguments
col_vec <- colorRampPalette(colors = c("#B2182B","#FFFFFF","#2166AC"))(220)
start_lim = -2
mid_pt = 0
end_lim = 2
title_text = "Water storage change (cm/year)"

# map
map_tws <- ggplot()+
  geom_sf(data=countries_sf,fill="#E3E1E1")+
  geom_sf(data=grace_sf,
          aes(fill=delta_wd_cm_yr),
          color=NA)+
  geom_sf(data=countries_sf,fill=NA)+
  xlim(-14000000,16807980)+ # makes sure map is centered
  scale_fill_gradientn(colors = col_vec,
                       na.value = "#E3E1E1",
                       values=rescale(c(start_lim, (mid_pt+start_lim)/2, mid_pt-0.1, mid_pt, mid_pt+0.1, (end_lim+mid_pt)/2, end_lim)),
                       limits=c(start_lim,end_lim),
                       oob=squish) +
  coord_sf(crs=st_crs(robin_proj),expand=F)+
  labs(fill=title_text)+
  guides(fill = guide_colorbar(title.position = "top"))+
  theme(legend.position = c(0.6,0.07),
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

ggsave(map_tws,
       filename="results/fig1.png",
       width = 12,
       height = 6,
       units = "in",
       dpi=300)

rm(list=setdiff(ls(), keep))