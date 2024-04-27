# load across-crop productivity data
grace_acrosspy <- read_dta("data/intermediate/grace_merged/across_crop_avg_pot_yld.dta")

# cleaning for bivariate map
grace_acrosspy_f <- grace_acrosspy %>% 
  filter(!is.na(py_z_wmean)) # discard NAs so they don't interfere with bivariate color scale


# create biscale
bisc_grace_acrosspy <- bi_class(grace_acrosspy_f,
                                x = py_z_wmean, y = delta_wd_cm_yr,
                                style = "quantile", dim=n_quantile)

# turn polygons into an sf object
bisc_grace_acrosspy_sf <- create_tile_sf_attr(df_name=bisc_grace_acrosspy,
                                              lonvar="lon",
                                              latvar="lat",
                                              widthvar="lonspan",
                                              heightvar="latspan")

# color palette
col_pal=inferno_pal2

# map
bimap_acrosspy <- ggplot()+
  geom_sf(data=bisc_grace_acrosspy_sf,
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

legend_acrosspy <- bi_legend(pal = col_pal,
                             dim=n_quantile,
                             xlab = "More Productive ",
                             ylab = "Water Gain ",
                             size = 10)

finalplot_acrosspy <- ggdraw() +
  draw_plot(bimap_acrosspy, 0, 0, 1, 1) +
  draw_plot(legend_acrosspy, -0.08, 0.15, 0.35, 0.35)

ggsave(finalplot_acrosspy,
       filename="results/fig2e.png",
       height=6,
       width=12,
       units = "in",
       dpi=300)

rm(list=setdiff(ls(), keep))