plot_edited <- function(x) {
  
  x$popup <- paste0(x$name,
                    '<br>(<b>',
                    x$edited, '</b>) - ',
                    'Area: ',
                    round(x$area, 1))
  
  x <- x %>%
    filter(!(edited == 0 | is.na(edited)))
  
  x$edited <- factor(x$edited, 
                     labels = c("Moved", "Unchanged", "Could not Match"))
  
  pal <- colorFactor(
    palette = "viridis",
    domain = x$edited)
  
  return(leaflet(x) %>%
    addTiles() %>%
    addCircleMarkers(lat = ~lat,
                     lng = ~long,
                     color = ~pal(edited),
                     popup = ~popup) %>%
    addLegend("bottomright", pal = pal, values = ~edited,
              title = "Edit Status",
              opacity = 1))
  
  
}