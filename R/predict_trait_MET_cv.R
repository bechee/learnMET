#' Trait prediction based on SNP and environmental data
#' This function should be used to assess the predictive ability according to
#' various cross-validation schemes.
#'
#' @param METData \code{list} An object created by the initial function of the
#' package create_METData()
#'
#' @param trait \code{character} Name of the trait under study for which a
#'
#' @param use_selected_markers \code{Logical} Whether to use a subset of markers
#' obtained from a previous step (see function select_markers()).
#'
#'
#'
#'
#'
#'
#'


predict_trait_MET_cv <- function(METData,
                                 trait,
                                 method = 'xgboost',
                                 use_selected_markers = T,
                                 geno_information = c('SNPs', 'PCs', 'PCs_G'),
                                 num_pcs = 200,
                                 lat_lon_included = T,
                                 year_included = F,
                                 cv_type = c('cv0', 'cv1', 'cv2'),
                                 cv0_type = c(
                                   'leave-one-environment-out',
                                   'leave-one-site-out',
                                   'leave-one-year-out',
                                   'forward-prediction'
                                 ),
                                 nb_folds_cv1 = 5,
                                 repeats_cv1 = 50,
                                 nb_folds_cv2 = 5,
                                 repeats_cv2 = 50,
                                 include_env_predictors = T,
                                 list_env_predictors = NULL,
                                 plot_PA = T,
                                 path_plot_PA = ''
                                 ,
                                 ...) {
  geno = METData$geno
  
  
  # Genotype matrix with SNP covariates selected if these should be added
  # as specific additional covariates (in addition to the main genetic effects).
  
  if (use_selected_markers == T &
      length(METData$selected_markers) > 0) {
    SNPs = geno[, colnames(METData$geno) %in% METData$selected_markers]
    SNPs$geno_ID = rownames(SNPs)
  } else if (use_selected_markers == T &
             length(METData$selected_markers) == 0) {
    cat(paste(
      'SNP covariates required to be used but no list of selected markers', 
      'available.\nPlease use select_markers() and use the output of this',
      'function to run predict_trait_MET_cv() with selected SNP covariates.'
    ))
  } else{
    cat('No specific additional SNP covariates will be used in analyses.')
  }
  
  
  # Check METData$ECs_computed to see if ECs were correctly downloaded via the
  # package when these are required by the user.
  
  if (include_env_predictors &
      METData$compute_ECs & "ECs_computed" %notin% names(METData)) {
    stop(
      'The weather-based covariates were not computed. Please use the
         function get_ECs() to obtain environmental predictors.'
    )
  }
  
  if (include_env_predictors &
      is.null(METData$env_data)) {
    stop(
      'No environmental covariates found in METData$env_data. Please set the
      argument "compute_ECs" to TRUE when using create_METData(), and then run
      function get_ECs() to obtain environmental predictors based on weather
      data retrieved from NASA-POWER.'
    )
  }
  # If no specific list of environmental predictors provided, all of the
  # environmental predictors present in METData$env_data are used as predictors.
  if (is.null(list_env_predictors) &
      include_env_predictors & nrow(METData$env_data) > 0) {
    list_env_predictors = colnames(METData$env_data)[colnames(METData$env_data) %notin%
                                                       c('IDenv', 'year', 'location', 'longitude', 'latitude')]
    
    
  }
  
  env_predictors = METData$env_data
  
  
  # Select phenotypic data for the trait under study and remove NA in phenotypes
  
  pheno = METData$pheno[, c("geno_ID", "year" , "location", "IDenv", trait)][complete.cases(METData$pheno[, c("geno_ID", "year" , "location", "IDenv", trait)]), ]
  
  
  # Create cross-validation random splits according to the type of selected CV
  
  # Generate a seed
  seed_generated <- sample(size = 1, 1:2 ^ 15)
  
  if (cv_type == 'cv1') {
    splits <-
      predict_cv1(
        pheno_data = pheno,
        nb_folds = nb_folds_cv1,
        reps = repeats_cv1,
        seed = seed_generated
      )
  }
  
  if (cv_type == 'cv2') {
    splits <-
      predict_cv2(
        pheno_data = pheno,
        nb_folds = nb_folds_cv2,
        reps = repeats_cv2,
        seed = seed_generated
      )
  }
  
  
  
  if (cv_type == 'cv0') {
    splits <-
      predict_cv0(pheno_data = pheno,
                  type = cv0_type)
  }
  
  ###############################
  ###############################
  
  ## PROCESSING AND SELECTING PREDICTORS FOR FITTING THE MODEL ##
  
  processing_all_splits = lapply(splits,
                                 function(x) {
                                   processing_train_test_split(
                                     split = x,
                                     geno_data = geno,
                                     geno_information = geno_information,
                                     use_selected_markers = use_selected_markers,
                                     SNPs = SNPs,
                                     list_env_predictors = list_env_predictors,
                                     include_env_predictors = include_env_predictors,
                                     lat_lon_included = lat_lon_included,
                                     year_included = year_included
                                   )
                                 })
  
  ##  FITTING ALL TRAIN/TEST SPLITS OF THE EXTERNAL CV SCHEME ##
  
  fitting_all_splits = lapply(processing_all_splits,
                              function(x) {
                                fitting_train_test_split(split = x,
                                                         prediction_method = method,
                                                         seed = seed_generated)
                              })
  
  
  ## VISUALIZATION OF THE PREDICTIVE ABILTIES ACCORDING TO THE SELECTED CV SCHEME ##
  
  plot_results_cv(
    results_fitted_splits = fitting_all_splits,
    cv_type = cv_type,
    cv0_type = cv0_type
  )
  
  
  ## RETURNING RESULTS ALONG WITH THE SEED USED
  
  return(list('list_results_cv' = fitting_all_splits, 'seed_used' = seed_generated))
  
  
}