#' Plot cross-validated results for the ML model and the trait under study.
#'
#' @description
#' Prediction accuracy is always computed on an environmental basis (i.e.  the 
#' correlations between the observed and predicted values are calculated within 
#' the same environment, no matter what is the cross-validation scheme used).
#' @param fitting_all_splits results obtained using the function 
#'   [fit_cv_split()] for all train/test partitions.
#'   
#' @param trait \code{character} used in the [predict_trait_MET_cv()] function
#'   called.
#' 
#' @param info_environments \code{data.frame} used in the 
#'   [predict_trait_MET_cv()]. Typically METData$info_environments.
#' @param cv_type \code{character} CV type used in the [predict_trait_MET_cv()]
#'  function called.
#' @param cv0_type \code{character} For CV0 type, different possibilities are:
#'   "leave-one-environment-out", "leave-one-site-out", "leave-one-location-out".
#' @param path_folder  \code{character} Path where plots should be saved.
#' @param nb_folds_cv1  \code{numeric}  Number of folds used in the CV1 scheme.
#' @param repeats_cv1 \code{numeric}  Number of repeats in the CV1 scheme.
#' @param nb_folds_cv2 \code{numeric}  Number of folds used in the CV2 scheme.
#' @param repeats_cv2 \code{numeric}  Number of repeats in the CV2 scheme.
#'   
#' @return Plots are directly saved in the path_folder.
#' @author Cathy C. Westhues \email{cathy.jubin@@hotmail.com}
#' @export
#'
plot_results_cv <-
  function(fitting_all_splits,
           trait,
           info_environments,
           cv_type,
           cv0_type,
           path_folder,
           nb_folds_cv1,
           repeats_cv1,
           nb_folds_cv2,
           repeats_cv2) {

    prediction_method <- fitting_all_splits[[1]]$prediction_method
    cat('Plot results of CV evaluation saved in ',path_folder)

    
    if (cv_type == 'cv0') {
      if (cv0_type == 'leave-one-environment-out') {
        list_envs <-
          vapply(
            fitting_all_splits, 
            FUN = function(x){
              unique(as.character(x[["cor_pred_obs"]][, 'IDenv']))
            }, 
            FUN.VALUE = character(1)
         )
        
        PA <-
          sapply(fitting_all_splits, function(x)
            as.numeric(x[['cor_pred_obs']][, 'COR']))
        
        df <- as.data.frame(cbind(list_envs, PA))
        
        colnames(df) <- c('IDenv', 'Prediction_accuracy')
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        pdf(file = paste0(
                 path_folder,
                 '/cv0_leave1environmentout_',
                 prediction_method,
                 '.pdf'
               ),
               height = 5,
               width = 7
        )
        p <-
          ggplot(df,
                 mapping = aes(
                   x = reorder(IDenv, Prediction_accuracy),
                   y = Prediction_accuracy,
                   group = 1,
                   ymin = 0,
                   ymax = 1
                 )) + geom_line() +
          xlab('Predicted environment') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-environment-out CV scheme') +
          theme(axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          ))
        print(plot(p))
        dev.off()
      }
      
      
      if (cv0_type == 'leave-one-year-out') {
        list_envs <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'IDenv']
            ))))
        
        
        list_years <-
          info_environments[match(list_envs, info_environments$IDenv), 'year']
        
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.numeric(as.data.frame(x[['cor_pred_obs']])[, 'COR'])))
        
        df <- as.data.frame(cbind(list_years, PA))
        
        colnames(df) <- c('year', 'Prediction_accuracy')
        df$year <- as.factor(df$year)
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        
        df2 <- dplyr::count(df, year)
        
        # Use boxplot only if for each year, more than 1 location tested
        
        if (all(df2$n == 1)) {
          pdf(file = paste0(
                   path_folder,
                   '/cv0_leave1yearout_show_year_',
                   prediction_method,
                   '.pdf'
                 ),
                 height = 5,
                 width = 7
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(year, -Prediction_accuracy),
                     y = Prediction_accuracy,
                     group = 1,
                     ymin = 0,
                     ymax = 1
                   )) + geom_line() +
            geom_text(data = df2, aes(
              x = year,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Year to predict (average over all sites)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-year-out CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
          print(plot(p))
          dev.off()
          
        }
        
        else{
          pdf(file = paste0(
                   path_folder,
                   '/cv0_leave1yearout_show_year_',
                   prediction_method,
                   '.pdf'
                 ),
                 height = 5,
                 width = 7
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(year, -Prediction_accuracy),
                     y = Prediction_accuracy,
                     ymin = 0,
                     ymax = 1
                   )) + geom_boxplot() +
            geom_text(data = df2, aes(
              x = year,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Year to predict (average over all sites)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-year-out CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
          print(plot(p))
          dev.off()
          
        }
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'COR']
            ))))
        
        
        df <- as.data.frame(cbind(list_envs, PA))
        
        colnames(df) <- c('IDenv', 'Prediction_accuracy')
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        pdf(file = paste0(
                 path_folder,
                 '/cv0_leave1yearout_show_env_',
                 prediction_method,
                 '.pdf'
               ),
               height = 5,
               width = 7
        )
        p <-
          ggplot(df,
                 mapping = aes(
                   x = reorder(IDenv,-Prediction_accuracy),
                   y = Prediction_accuracy,
                   group = 1,
                   ymin = 0,
                   ymax = 1
                 )) + geom_line() +
          xlab('Predicted environment') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-year-out CV scheme') +
          theme(axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          ))
        print(plot(p))
        dev.off()
        
      }
      
      if (cv0_type == 'forward-prediction') {
        list_envs <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'IDenv']
            ))))
        
        
        list_years <-
          info_environments[match(list_envs, info_environments$IDenv), 'year']
        
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.numeric(as.data.frame(x[['cor_pred_obs']])[, 'COR'])))
        
        df <- as.data.frame(cbind(list_years, PA))
        
        colnames(df) <- c('year', 'Prediction_accuracy')
        df$year <- as.factor(df$year)
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        
        df2 <- plyr::count(df, year)
        
        # Use boxplot only if for each year, more than 1 location tested
        
        if (all(df2$n == 1)) {
          pdf(file = paste0(
                   path_folder,
                   '/cv0_forwardprediction_show_year_',
                   prediction_method,
                   '.pdf'
                 ),
                 height = 5,
                 width = 7
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(year, -Prediction_accuracy),
                     y = Prediction_accuracy,
                     group = 1,
                     ymin = 0,
                     ymax = 1
                   )) + geom_line() +
            geom_text(data = df2, aes(
              x = year,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Year to predict (average over all sites)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Forward-year CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
          print(plot(p))
          dev.off()
          
        }
        
        else{
          pdf(file = paste0(
                   path_folder,
                   '/cv0_forwardprediction_show_year_',
                   prediction_method,
                   '.pdf'
                 ),
                 height = 5,
                 width = 7
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(year, -Prediction_accuracy),
                     y = Prediction_accuracy,
                     ymin = 0,
                     ymax = 1
                   )) + geom_boxplot() +
            geom_text(data = df2, aes(
              x = year,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Year to predict (average over all sites)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Forward-year CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
          
          print(plot(p))
          dev.off()
        }
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'COR']
            ))))
        
        
        df <- as.data.frame(cbind(list_envs, PA))
        
        colnames(df) <- c('IDenv', 'Prediction_accuracy')
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        pdf(file = paste0(
                 path_folder,
                 '/cv0_forwardprediction_show_env_',
                 prediction_method,
                 '.pdf'
               ),
               height = 5,
               width = 7
        )
        p <-
          ggplot(df,
                 mapping = aes(
                   x = reorder(IDenv,-Prediction_accuracy),
                   y = Prediction_accuracy,
                   group = 1,
                   ymin = 0,
                   ymax = 1
                 )) + geom_line() +
          xlab('Predicted environment') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Forward-year CV scheme') +
          theme(axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          ))
        
        print(plot(p))
        dev.off()
       
      }
      
      if (cv0_type == 'leave-one-site-out') {
        list_envs <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'IDenv']
            ))))
        
        
        list_locations <-
          info_environments[match(list_envs, info_environments$IDenv), 'location']
        
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.numeric(as.data.frame(x[['cor_pred_obs']])[, 'COR'])))
        
        df <- as.data.frame(cbind(list_locations, PA))
        
        colnames(df) <- c('location', 'Prediction_accuracy')
        df$location <- as.factor(df$location)
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        
        df2 <- plyr::count(df, location)
        
        if (all(df2$n == 1)) {
          pdf(file = paste0(
                   path_folder,
                   '/cv0_leave1locationout_show_location_',
                   prediction_method,
                   '.pdf'
                 ),
                 width = 7,
                 height = 5
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(location,-Prediction_accuracy),
                     y = Prediction_accuracy,
                     ymin = 0,
                     ymax = 1
                   )) + geom_line() +
            geom_text(data = df2, aes(
              x = location,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Location to predict (average over all years)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-location-out CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
          print(plot(p))
          dev.off()
        }
        
        else{
          pdf(file = paste0(
                   path_folder,
                   '/cv0_leave1locationout_show_location_',
                   prediction_method,
                   '.pdf'
                 ),
                 height = 5,
                 width = 7
          )
          p <-
            ggplot(df,
                   mapping = aes(
                     x = reorder(location,-Prediction_accuracy),
                     y = Prediction_accuracy,
                     ymin = 0,
                     ymax = 1
                   )) + geom_boxplot() +
            geom_text(data = df2, aes(
              x = location,
              y = 1,
              label = paste0(n, ' environment(s)')
            )) +
            xlab('Location to predict (average over all years)') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-location-out CV scheme') +
            theme(axis.text.x = element_text(
              angle = 90,
              vjust = 0.5,
              hjust = 1
            ))
         print(plot(p))
         dev.off()
        }
        
        
        PA <-
          as.vector(sapply(fitting_all_splits, function(x)
            as.character(unique(
              as.data.frame(x[["cor_pred_obs"]])[, 'COR']
            ))))
        
        
        df <- as.data.frame(cbind(list_envs, PA))
        
        colnames(df) <- c('IDenv', 'Prediction_accuracy')
        
        df$Prediction_accuracy <-
          as.numeric(as.character(df$Prediction_accuracy))
        pdf(file = paste0(
                 path_folder,
                 '/cv0_leave1locationout_show_env_',
                 prediction_method,
                 '.pdf'
               ),
               height = 5,
               width = 7
        )
        p <-
          ggplot(df,
                 mapping = aes(
                   x = reorder(IDenv,-Prediction_accuracy),
                   y = Prediction_accuracy,
                   group = 1,
                   ymin = 0,
                   ymax = 1
                 )) + geom_line() +
          xlab('Predicted environment') + ylab(paste0('Prediction accuracy for the trait ', trait)) + ggtitle('Leave-one-location-out CV scheme') +
          theme(axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          ))
        print(plot(p))
        dev.off()
      }
    }
    
    if (cv_type == 'cv1') {
      PA <-
        unlist(sapply(fitting_all_splits, function(x)
          x[['cor_pred_obs']]['COR']))
      
      df <- as.data.frame(PA)
      
      colnames(df) <- c('Prediction_accuracy')
      df$Prediction_accuracy <-
        as.numeric(as.character(df$Prediction_accuracy))
      
      fun_mean <- function(x) {
        return(data.frame(y = round(mean(x), 3), label = round(mean(x, na.rm = T), 3)))
      }
      
      fun_sd <- function(x) {
        return(data.frame(y = 1, label = paste0('sd =', round(
          sd(x, na.rm = T), 3
        ))))
      }
      
      pdf(file = paste0(path_folder, '/cv1_', prediction_method, '.pdf'),
             height = 5,
             width = 7
      )
      p <-
        ggplot(df,
               mapping = aes(
                 x = 'CV1',
                 y = Prediction_accuracy,
                 group = 1,
                 ymin = 0,
                 ymax = 1
               )) + geom_boxplot() +
        xlab('CV1') + ylab(
          paste0(
            'Average prediction accuracy for the trait ',
            trait,
            '\n using ',
            nb_folds_cv1,
            '-fold CV with ',
            repeats_cv1,
            'repeats'
          )
        ) + stat_summary(
          fun = mean,
          geom = "point",
          colour = "darkred",
          size = 3
        ) +
        stat_summary(fun.data = fun_mean,
                     geom = "text",
                     vjust = -0.7) +
        stat_summary(fun.data = fun_sd,
                     geom = "text",
                     vjust = -0.7) + ggtitle('CV1 scheme') +
        theme(axis.text.x = element_text(
          angle = 90,
          vjust = 0.5,
          hjust = 1
        ))
      print(plot(p))
      dev.off()
    }
    
    if (cv_type == 'cv2') {
      PA <-
        unlist(sapply(fitting_all_splits, function(x)
          x[['cor_pred_obs']]['COR']))
      
      df <- as.data.frame(PA)
      
      colnames(df) <- c('Prediction_accuracy')
      df$Prediction_accuracy <-
        as.numeric(as.character(df$Prediction_accuracy))
      
      fun_mean <- function(x) {
        return(data.frame(y = round(mean(x), 3), label = round(mean(x, na.rm = T), 3)))
      }
      
      fun_sd <- function(x) {
        return(data.frame(y = 1, label = paste0('sd =', round(
          sd(x, na.rm = T), 3
        ))))
      }
      
      pdf(file = paste0(path_folder, '/cv2_', prediction_method, '.pdf'),
             height = 5,
             width = 7
      )
      p <-
        ggplot(df,
               mapping = aes(
                 x = 'CV2',
                 y = Prediction_accuracy,
                 group = 1,
                 ymin = 0,
                 ymax = 1
               )) + geom_boxplot() +
        xlab('CV2') + ylab(
          paste0(
            'Average prediction accuracy for the trait ',
            trait,
            '\n using ',
            nb_folds_cv2,
            '-fold CV with ',
            repeats_cv2,
            'repeats'
          )
        ) + stat_summary(
          fun = mean,
          geom = "point",
          colour = "darkred",
          size = 3
        ) +
        stat_summary(fun.data = fun_mean,
                     geom = "text",
                     vjust = -0.7) +
        stat_summary(fun.data = fun_sd,
                     geom = "text",
                     vjust = -0.7) + ggtitle('CV2 scheme') +
        theme(axis.text.x = element_text(
          angle = 90,
          vjust = 0.5,
          hjust = 1
        ))
      print(plot(p))
      dev.off()
    
    }
    
  }
