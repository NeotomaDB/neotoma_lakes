pull_chron_table <- function(version, all_ds) {
  if (!paste0('chron_control_status_version_', version, '.csv') %in% list.files(paste0('data/version_',version))) {
    
    controls <- all_ds %>% map(function(x)try(neotoma::get_chroncontrol(x)))
    
    chron_table <- list()
    
    for(i in 1:length(all_ds)) {
      if(length(controls[[i]][[1]]) == 1 | 
         'try-error' %in% class(controls[[i]]) |
         all(is.na(controls[[i]][[1]]$chron.control))) {
        chron_table[[i]] <- data.frame(dsid = all_ds[[i]]$dataset$dataset.meta$dataset.id,
                                       stid = all_ds[[i]]$dataset$site.data$site.id)
      } else {
        
        type_count <- controls[[i]][[1]]$chron.control %>%
          group_by(control.type) %>%
          summarise(n = n()) %>% 
          mutate(control.type = as.character(control.type))
        
        if (any(is.na(type_count$control.type))) {
          type_count$control.type[is.na(type_count$control.type)] <- "No control"
        }
        
        if (all(is.na(diff(controls[[i]][[1]]$chron.control$age)))) {
          max_interval <- -999
          avg_interval <- -999
        } else {
          avg_interval <- mean(diff(controls[[i]][[1]]$chron.control$age), na.rm = TRUE)
          max_interval <-  max(diff(controls[[i]][[1]]$chron.control$age), na.rm = TRUE)
        }
        
        chron_table[[i]] <- data.frame(i = i,
                                       dsid = all_ds[[i]]$dataset$dataset.id,
                                       stid = all_ds[[i]]$site.data$site.id,
                                       controls = sum(type_count$n, na.rm=TRUE),
                                       type_count,
                                       avg_int = avg_interval,
                                       max_int = max_interval,
                                       stringsAsFactors = FALSE) %>%
          dcast(i + dsid + stid + avg_int + max_int + controls ~ control.type, 
                value.var = 'n')
        
      }
    }
    
    control_output <- chron_table %>% bind_rows()
    
    control_output[is.na(control_output)] <- 0
    
    readr::write_csv(control_output,
                     paste0('data/version_',version,'/chron_control_status_version_', version, '.csv'))
  } else {
    control_output <- readr::read_csv(paste0('data/version_',
                                             version,
                                             '/chron_control_status_version_', version, '.csv'))
  }
  
  return(control_output)
}