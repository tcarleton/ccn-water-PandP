# load crop productivity data
grace_croppy <- read_dta("data/intermediate/grace_merged/crop_spec_pot_yld.dta")

# imitate the "bi_class" function as it does not work for some reason here
bisc_wheat_prod <- bi_class(grace_croppy,
                            x = whea_aei_yld, y = delta_wd_cm_yr,
                            style = "quantile", dim=n_quantile)

# turn polygons into an sf object
bisc_wheat_prod_sf <- create_tile_sf_attr(df_name=bisc_wheat_prod,
                                          lonvar="lon",
                                          latvar="lat",
                                          widthvar="lonspan",
                                          heightvar="latspan")

# color palette
col_pal=inferno_pal2

# map
bimap_wheat_prod <- ggplot()+
  geom_sf(data=bisc_wheat_prod_sf,
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


legend_wheat_prod <- bi_legend(pal = col_pal,
                              dim=n_quantile,
                              xlab = "Wheat Productivity ",
                              ylab = "Water Gain ",
                              size = 10)

finalplot_wheat_prod <- ggdraw() +
  draw_plot(bimap_wheat_prod, 0, 0, 1, 1) +
  draw_plot(legend_wheat_prod, -0.08, 0.15, 0.35, 0.35)

ggsave(finalplot_wheat_prod,
       filename="results/figA4c.png",
       height=6,
       width=12,
       units = "in",
       dpi=300)

rm(list=setdiff(ls(), keep))