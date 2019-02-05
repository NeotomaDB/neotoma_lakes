clean_matches <- function(x, keep, sitedataset) {
  
  output <- data.frame(sitename = sitedataset$name,
                       dsid = sitedataset$dsid,
                       stid = sitedataset$stid,
                       lat  = sitedataset$lat,
                       long = sitedataset$long,
                       area = NA,
                       source = NA)
    
  for (i in unique(sitedataset$stid)) {
    
    if (i %in% x$stid) {
      
      subset <- x %>% filter(stid == i)
      st <- output$stid == i
      
      if (length(unique(subset$area)) == 1) {
        
        st <- output$stid == i
        output$area[st]  <- unique(subset$area)
        if(length(unique(subset$source)) == 1) {
          output$source[st] <- unique(subset$source)  
        } else {
          if (keep %in% unique(subset$source)) {
            output$source[st] <- keep
          } else {
            output$source[st] <- "Multiple source matches."
          }
        }
        
        
      } else {
        subset <- subset %>% filter(source == keep)
        assertthat::assert_that(length(unique(subset$area)) == 1,
                                msg = "There's still duplicates")
        
        output$area[st]  <- unique(subset$area)
        output$source[st] <- unique(subset$source)
        
      }
    }
  }
  
  return(output %>% filter(!is.na(area)))
  
}