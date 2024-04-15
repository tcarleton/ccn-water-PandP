# load grace data
grace <- read_dta("data/input/grace/grace.dta")

# restrict to arable land and cells with valid delta_TWS
grace <- grace %>%
  filter(!((past_area_frac == 0 & sage_crop_area_frac == 0) |
             (is.na(past_area_frac) & is.na(sage_crop_area_frac)) |
             (is.na(past_area_frac) & sage_crop_area_frac == 0) |
             (past_area_frac == 0 & is.na(sage_crop_area_frac)))) %>%
  filter(!is.na(delta_wd_cm_yr))

# create biscale
bisc_tws_rain <- bi_class(grace,
                          x = rain_cm_yr, y = delta_wd_cm_yr,
                          style = "quantile", dim=n_quantile)

# turn polygons into an sf object
bisc_tws_rain_sf <- create_tile_sf_attr(df_name=bisc_tws_rain,
                                        lonvar="lon",
                                        latvar="lat",
                                        widthvar="lonspan",
                                        heightvar="latspan")

# color palette
col_pal=inferno_pal

# map
bimap_tws_rain <- ggplot()+
  geom_sf(data=bisc_tws_rain_sf,
          aes(fill=bi_class),
          color=NA,
          show.legend = F)+
  geom_sf(data=countries_sf,
          fill=NA)+
  xlim(-14000000,16807980)+ # makes sure map is centered
  bi_scale_fill(pal = col_pal, dim=n_quantile, na.value="white")+
  coord_sf(crs=st_crs(robin_proj), expand=F)+
  theme(axis.title = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        plot.background = element_rect(color = 'white'),
        plot.margin = margin(0, 0, 0, 0),
        panel.background = element_blank(),
        panel.grid.major = element_blank())

legend_tws_rain <- bi_legend(pal = col_pal,
                               dim=n_quantile,
                               xlab = "More Rainfall ",
                               ylab = "Water Gain ",
                               size = 10)

finalplot_tws_rain <- ggdraw() +
  draw_plot(bimap_tws_rain, 0, 0, 1, 1) +
  draw_plot(legend_tws_rain, -0.08, 0.15, 0.35, 0.35)

ggsave(finalplot_tws_rain,
       filename="results/figA1a.png",
       height=6,
       width=12,
       units = "in",
       dpi=300)

rm(list=setdiff(ls(), keep))