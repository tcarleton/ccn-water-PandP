# load crop productivity data
grace_croppy <- read_dta("data/intermediate/grace_merged/crop_spec_pot_yld.dta")

# imitate the "bi_class" function as it does not work for some reason here
bisc_rice_prod <- grace_croppy %>% 
  mutate(q_rice_aei_yld=case_when(rice_aei_yld<=quantile(rice_aei_yld,0.25) ~ 1,
                                  rice_aei_yld>quantile(rice_aei_yld,0.25) & rice_aei_yld<=quantile(rice_aei_yld,0.5) ~ 2,
                                  rice_aei_yld>quantile(rice_aei_yld,0.5) & rice_aei_yld<=quantile(rice_aei_yld,0.75) ~ 3,
                                  rice_aei_yld>quantile(rice_aei_yld,0.75) ~ 4),
         q_delta_wd_cm_yr=case_when(delta_wd_cm_yr<=quantile(delta_wd_cm_yr,0.25) ~ 1,
                                    delta_wd_cm_yr>quantile(delta_wd_cm_yr,0.25) & delta_wd_cm_yr<=quantile(delta_wd_cm_yr,0.5) ~ 2,
                                    delta_wd_cm_yr>quantile(delta_wd_cm_yr,0.5) & delta_wd_cm_yr<=quantile(delta_wd_cm_yr,0.75) ~ 3,
                                    delta_wd_cm_yr>quantile(delta_wd_cm_yr,0.75) ~ 4),
         bi_class=paste0(q_rice_aei_yld,"-",q_delta_wd_cm_yr))

# turn polygons into an sf object
bisc_rice_prod_sf <- create_tile_sf_attr(df_name=bisc_rice_prod,
                                         lonvar="lon",
                                         latvar="lat",
                                         widthvar="lonspan",
                                         heightvar="latspan")

# color palette
col_pal=inferno_pal2

# map
bimap_rice_prod <- ggplot()+
  geom_sf(data=bisc_rice_prod_sf,
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


legend_rice_prod <- bi_legend(pal = col_pal,
                              dim=n_quantile,
                              xlab = "Rice Productivity ",
                              ylab = "Water Gain ",
                              size = 10)

finalplot_rice_prod <- ggdraw() +
  draw_plot(bimap_rice_prod, 0, 0, 1, 1) +
  draw_plot(legend_rice_prod, -0.08, 0.15, 0.35, 0.35)

ggsave(finalplot_rice_prod,
       filename="results/figA4a.png",
       height=6,
       width=12,
       units = "in",
       dpi=300)

rm(list=setdiff(ls(), keep))