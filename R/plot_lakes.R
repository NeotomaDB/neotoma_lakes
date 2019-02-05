plot_linked <- function(x) {
  
  x$popup   <- paste0('<b>',x$site.name,'</b><hr>',
                                   '<a href=http://apps.neotomadb.org/explorer/?siteids=',
                                   x$stid,
                                   '>Explorer Link</a>')
  
  leaflet(x)  %>%
    addProviderTiles('Stamen.TonerLite') %>%
    addCircleMarkers(lng = ~long, lat = ~lat,
                     radius = 3,
                     stroke = FALSE,
                     popup = ~popup) %>%
    addLegend("bottomright",
              colors = c('red', 'blue'),
              labels = c('Linked', 'Not Linked'),
              title = "Linked To Hydro Database",
              opacity = 1)  
  
}