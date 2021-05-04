% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict_cv1.R
\name{predict_cv1}
\alias{predict_cv1}
\title{Get train/test splits of the phenotypic MET dataset based on CV1.}
\usage{
predict_cv1(pheno_data, nb_folds = nb_folds_cv1, reps = repeats_cv1)
}
\arguments{
\item{pheno_data}{\code{data.frame} Dataset containing phenotypic outcome
data, as well as the predictor variables}

\item{nb_folds}{\code{numeric} Number of folds in the CV process}

\item{reps}{\code{numeric} Number of repeats of the k-folds CV}
}
\value{
a \code{list} which contains nb_folds x reps elements.
Each element of the list corresponds to a list with two elements:
\itemize{
\item \code{data.frame} Dataset with all observations for the training set
\item \code{data.frame} Dataset with all observations for the test set
}
}
\description{
Get train/test splits of the phenotypic MET dataset based on a
number of random k-folds partitions determined by the user, according to the
type CV1. Creation of the train/test splits based on phenotypic data, so that
all the phenotypes from the same line appear in same fold (prediction of new
lines never observed in any environment).
}