#' Plot variable importance scores
#'
#' @description
#' Internal function of [predict_trait_MET_cv()].\cr
#' Plots are done at the CV scheme level from the , which means that:
#' \enumerate{
#'   \item If CV0 is evaluated, the plot shows the 40 most important variables according to the predicted element (i.e. site, year or environment).
#'   \item For CV1 and CV2, variable importance plots are based on a average of the importance of each feature over all training/test splits.
#' }
#'
#' Variable importance can be calculated based on model agnostic approaches (permutation-based methods, like for `stacking_reg_1` or `DL_reg`), or
#' on model-specific methods (gain metric for GBDT methods `xgb_reg`).
#'
#'
#' @param fitting_all_splits a \code{list} which is the list of results from the fitting step on all train/test partitions
#' @param cv_type A \code{character} with one out of `cv0` (prediction of new
#'   environments), `cv00` (prediction of new genotypes in new environments),
#'   `cv1` (prediction of new genotypes) or `cv2` (prediction of incomplete
#'   field trials).
#' @param cv0_type cv0_type A \code{character} with one out of
#'   `leave-one-environment-out`, `leave-one-site-out`,`leave-one-year-out`,
#'   `forward-prediction`.
#' @param path_folder a \code{character} where the plots should be saved.
#' @param nb_folds_cv1 A \code{numeric} Number of folds used in the CV1 scheme.
#'
#' @param repeats_cv1 A \code{numeric} Number of repeats in the CV1 scheme.
#'
#' @param nb_folds_cv2 A \code{numeric} Number of folds used in the CV2 scheme.
#'
#' @param repeats_cv2 A \code{numeric} Number of repeats in the CV2 scheme.
#'
#' @return A variable importance plot is saved in the `path_folder`. No specific object returned.
#'
#' @author Cathy C. Westhues \email{cathy.jubin@@hotmail.com}
#' @export
#'

plot_results_vip_cv <-
  function(fitting_all_splits,
           cv_type,
           cv0_type,
           path_folder,
           nb_folds_cv1,
           repeats_cv1,
           nb_folds_cv2,
           repeats_cv2) {
    prediction_method <- fitting_all_splits[[1]]$prediction_method
    
    
    if (cv_type == 'cv0') {
      if (cv0_type == 'leave-one-environment-out') {
        VIP <-
          lapply(fitting_all_splits, function(x)
            x['vip'])
        
        VIP <- do.call('rbind', VIP)
        
        for (j in unique(VIP$Variable)) {
          if (length(which(VIP$Variable == j)) < length(fitting_all_splits)) {
            m <-
              length(fitting_all_splits) - length(which(VIP$Variable == j))
            supp <- matrix(c(j, 0),
                           nrow = m,
                           ncol = 2,
                           byrow = T)
            colnames(supp) <- colnames(VIP)
            VIP <- rbind(VIP, supp)
          }
          
        }
        
        VIP$Importance <- as.numeric(VIP$Importance)
        
        VIP <- as.data.frame(VIP %>%
                               group_by(Variable) %>%
                               dplyr::mutate(Mean = mean(Importance, na.rm = TRUE)))
        
        
        
        VIP_selected_var <-
          as.data.frame(unique(VIP[, c(1, 3)])) %>% top_n(., wt = Mean, n = 40)
        
        VIP <- VIP[VIP$Variable %in% VIP_selected_var$Variable, ]
        
        VIP$Mean <- as.numeric(VIP$Mean)
        
        if (type == 'model_specific') {
          p <-
            ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab('Average relative importance (gain metric) over models fitted on training set') + xlab('Top 40 predictor variables\n') +
            geom_boxplot()  + coord_flip()
        } else {
          p <-
            ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab(
              'Average permuted importance scores over models fitted on training sets from CV0-leave-1-environment-out'
            ) + xlab('Top 40 predictor variables\n') +
            geom_boxplot()  + coord_flip()
          
        }
        
        
        ggsave(
          p,
          filename = paste0(
            path_folder,
            '/cv0_leave1environmentout_',
            prediction_method,
            '_Variable_Importance.pdf'
          ),
          height = 8,
          width = 12,
          device = 'pdf'
        )
        
      }
      
      
      if (cv0_type == 'leave-one-year-out') {
        list_predicted_years <-
          vapply(fitting_all_splits, function(x)
            as.character(unique(x[['predictions_df']][, 'year'])), character(1))
        
        VIP <-
          vapply(fitting_all_splits, function(x)
            x['vip'], FUN.VALUE = data.frame(1))
        
        
        for (j in 1:length(list_predicted_years)) {
          VIP[[j]]$year <- list_predicted_years[j]
          VIP[[j]] <- top_n(VIP[[j]], wt = Importance, n = 40)
          
        }
        
        
        VIP <- do.call('rbind', VIP)
        
        predicted_years <-
          paste0('Predicted year: ', list_predicted_years)
        names(predicted_years) <- list_predicted_years
        
        
        
        if (prediction_method == 'xgb_reg') {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, year),
              y = Importance
            )) + ylab('Relative importance (gain metric)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ year,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_years)
            ) + coord_flip()
        } else {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, year),
              y = Importance
            )) + ylab('Permutation-based VI scores (10 permutations)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ year,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_years)
            ) + coord_flip()
        }
        
        
        ggsave(
          p,
          filename = paste0(
            path_folder,
            '/cv0_leave1yearout_',
            prediction_method,
            '_Variable_Importance.pdf'
          ),
          height = 8,
          width = 12,
          device = 'pdf'
        )
        
        
        
        
      }
      
      if (cv0_type == 'forward_prediction') {
        list_predicted_years <-
          as.vector(lapply(fitting_all_splits, function(x)
            as.character(unique(x[['predictions_df']][, 'year']))))
        
        VIP <-
          vapply(fitting_all_splits, function(x)
            x['vip'], FUN.VALUE = data.frame(1))
        
        
        for (j in 1:length(list_predicted_years)) {
          VIP[[j]]$year <- list_predicted_years[[j]]
          VIP[[j]] <- top_n(VIP[[j]], wt = Importance, n = 40)
          
        }
        
        
        VIP <- do.call('rbind', VIP)
        
        predicted_years <-
          paste0('Predicted year: ', list_predicted_years)
        names(predicted_years) <- list_predicted_years
        
        
        if (prediction_method == 'xgb_reg') {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, year),
              y = Importance
            )) + ylab('Relative importance (gain metric)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ year,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_years)
            ) + coord_flip()
        } else {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, year),
              y = Importance
            )) + ylab('Permutation-based VI scores (10 permutations)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ year,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_years)
            ) + coord_flip()
        }
        
        ggsave(
          p,
          filename = paste0(
            path_folder,
            '/cv0_forwardprediction_',
            prediction_method,
            '_Variable_Importance.pdf'
          ),
          height = 8,
          width = 12,
          device = 'pdf'
        )
        
        
      }
      
      if (cv0_type == 'leave-one-site-out') {
        list_predicted_locations <-
          as.vector(lapply(fitting_all_splits, function(x)
            as.character(unique(x[['predictions_df']][, 'location']))))
        
        VIP <-
          vapply(fitting_all_splits, function(x)
            x['vip'], FUN.VALUE = data.frame(1))
        
        
        for (j in 1:length(list_predicted_locations)) {
          VIP[[j]]$location <- list_predicted_locations[[j]]
          VIP[[j]] <- top_n(VIP[[j]], wt = Importance, n = 40)
          
        }
        
        VIP <- do.call('rbind', VIP)
        
        predicted_loc <-
          paste0('Predicted location: ', list_predicted_locations)
        names(predicted_loc) <- list_predicted_locations
        
        
        if (prediction_method == 'xgb_reg') {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, location),
              y = Importance
            )) + ylab('Relative importance (gain metric)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ location,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_loc)
            ) + coord_flip()
        }
        else {
          p <-
            ggplot(VIP, aes(
              x = tidytext::reorder_within(Variable, Importance, location),
              y = Importance
            )) + ylab('Permutation-based VI scores (10 permutations)') + xlab('Top 40 predictor variables\n for each training set') +
            geom_boxplot() + facet_wrap(
              ~ location,
              ncol = 3,
              nrow = 3,
              scales = "free",
              labeller = as_labeller(predicted_loc)
            ) + coord_flip()
        }
        
        ggsave(
          p,
          filename = paste0(
            path_folder,
            '/cv0_leave1locationout_',
            prediction_method,
            '_Variable_Importance.pdf'
          ),
          height = 8,
          width = 12,
          device = 'pdf'
        )
        
        
      }
    }
    
    if (cv_type == 'cv1') {
      VIP <-
        vapply(fitting_all_splits, function(x)
          x['vip'], FUN.VALUE = data.frame(1))
      
      VIP <- do.call('rbind', VIP)
      
      for (j in unique(VIP$Variable)) {
        if (length(which(VIP$Variable == j)) < nb_folds_cv1 * repeats_cv1) {
          m <-
            nb_folds_cv1 * repeats_cv1 - length(which(VIP$Variable == j))
          supp <- matrix(c(j, 0),
                         nrow = m,
                         ncol = 2,
                         byrow = T)
          colnames(supp) <- colnames(VIP)
          VIP <- rbind(VIP, supp)
        }
        
      }
      
      VIP$Importance <- as.numeric(VIP$Importance)
      
      VIP <- as.data.frame(VIP %>%
                             group_by(Variable) %>%
                             dplyr::mutate(Mean = mean(Importance, na.rm = TRUE)))
      
      
      
      VIP_selected_var <-
        as.data.frame(unique(VIP[, c(1, 3)])) %>% top_n(., wt = Mean, n = 40)
      
      VIP <- VIP[VIP$Variable %in% VIP_selected_var$Variable, ]
      
      VIP$Mean <- as.numeric(VIP$Mean)
      
      if (prediction_method == 'xgb_reg') {
        p <-
          ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab(
            'Average relative importance (gain metric) over models fitted on training sets from CV1'
          ) + xlab('Top 40 predictor variables\n') +
          geom_boxplot()  + coord_flip()
      } else {
        p <-
          ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab('Average permuted importance scores over models fitted on training sets from CV1') + xlab('Top 40 predictor variables\n') +
          geom_boxplot()  + coord_flip()
        
      }
      
      
      ggsave(
        p,
        filename = paste0(
          path_folder,
          '/cv1_',
          prediction_method,
          '_Variable_Importance.pdf'
        ),
        height = 8,
        width = 12,
        device = 'pdf'
      )
      
      
      
    }
    
    if (cv_type == 'cv2') {
      VIP <-
        vapply(fitting_all_splits, function(x)
          x['vip'], FUN.VALUE = data.frame(1))
      
      VIP <- do.call('rbind', VIP)
      
      for (j in unique(VIP$Variable)) {
        if (length(which(VIP$Variable == j)) < nb_folds_cv2 * repeats_cv2) {
          m <-
            nb_folds_cv2 * repeats_cv2 - length(which(VIP$Variable == j))
          supp <- matrix(c(j, 0),
                         nrow = m,
                         ncol = 2,
                         byrow = T)
          colnames(supp) <- colnames(VIP)
          VIP <- rbind(VIP, supp)
        }
        
      }
      
      VIP$Importance <- as.numeric(VIP$Importance)
      
      VIP <- as.data.frame(VIP %>%
                             group_by(Variable) %>%
                             dplyr::mutate(Mean = mean(Importance, na.rm =
                                                         TRUE)))
      
      
      
      VIP_selected_var <-
        as.data.frame(unique(VIP[, c(1, 3)])) %>% top_n(., wt = Mean, n = 40)
      
      VIP <- VIP[VIP$Variable %in% VIP_selected_var$Variable, ]
      
      VIP$Mean <- as.numeric(VIP$Mean)
      
      if (prediction_method == 'xgb_reg') {
        p <-
          ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab(
            'Average relative importance (gain metric) over models fitted on training sets from CV2'
          ) + xlab('Top 40 predictor variables\n') +
          geom_boxplot()  + coord_flip()
      } else {
        p <-
          ggplot(VIP, aes(x = reorder(Variable, Importance), y = Importance)) + ylab('Average permuted importance scores over models fitted on training sets from CV2') + xlab('Top 40 predictor variables\n') +
          geom_boxplot()  + coord_flip()
      }
      
      
      ggsave(
        p,
        filename = paste0(
          path_folder,
          '/cv2_',
          prediction_method,
          '_Variable_Importance.pdf'
        ),
        height = 8,
        width = 12,
        device = 'pdf'
      )
      
    }
    
  }


#' Plot variable importance scores
#'
#' @description
#' Internal function of [predict_trait_MET()].\cr
#'
#' Variable importance can be calculated based on model agnostic approaches (permutation-based methods, like for `stacking_reg_1` or `DL_reg`), or
#' on model-specific methods (gain metric for GBDT methods `xgb_reg`).
#'
#'
#' @param x List of results from the model fitted on the complete training set
#' @param path_folder a \code{character} where the plots should be saved.
#' @return A variable importance plot is saved in the `path_folder`. No specific object returned otherwise.
#'
#' @author Cathy C. Westhues \email{cathy.jubin@@hotmail.com}
#' @export
#'

plot_results_vip <-
  function(x,
           path_plot,
           type) {
    x$Importance <- as.numeric(x$Importance)
    
    
    
    VIP_selected_var <-
      as.data.frame(x) %>% top_n(., wt = Importance, n = 40)
    
    x <- x[x$Variable %in% VIP_selected_var$Variable, ]
    
    
    
    if (type == 'model_specific') {
      p <-
        ggplot(x, aes(x = reorder(Variable, Importance), y = Importance)) + ylab('Average relative importance (gain metric) from model fitted using training set') + xlab('Top 40 predictor variables\n') +
        geom_boxplot()  + coord_flip() + theme(axis.title = element_text(size =
                                                                           19),
                                               axis.text = element_text(size = 15))
      ggsave(
        p,
        filename = paste0(
          path_plot,
          'Variable_Importance',
          '_modelspecific',
          '.pdf'
        ),
        height = 8,
        width = 12,
        device = 'pdf'
      )
      
    } else {
      p <-
        ggplot(x, aes(x = reorder(Variable, Importance), y = Importance)) + ylab('Average permuted feature importance from model fitted using training set') + xlab('Top 40 predictor variables\n') +
        geom_boxplot()  + coord_flip()
      ggsave(
        p,
        filename = paste0(
          path_plot,
          'Variable_Importance',
          '_modelagnostic',
          '.pdf'
        ),
        height = 8,
        width = 12,
        device = 'pdf'
      )
      
    }
    
    
    
    
  }