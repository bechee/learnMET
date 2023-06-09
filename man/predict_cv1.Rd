% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict_cv1.R
\name{predict_cv1}
\alias{predict_cv1}
\title{Get train/test splits of the phenotypic MET dataset based on CV1.}
\usage{
predict_cv1(pheno_data, nb_folds, reps, seed)
}
\arguments{
\item{pheno_data}{\code{data.frame} Dataset containing phenotypic outcome
data, as well as the predictor variables}

\item{nb_folds}{\code{numeric} Number of folds in the CV process. In CV1
lines are randomly assigned to folds: this ensures that all the records
of a given line are assigned to the same fold.}

\item{reps}{\code{numeric} Number of repeats of the k-folds CV}
}
\value{
a \code{cv_object} object which contains nb_folds x reps elements.
Each element of the object corresponds to a \code{split} object with two
elements:
\describe{
\item{training}{\code{data.frame} Dataset with all observations for the
training set.}
\item{test}{\code{data.frame} Dataset with all observations for the test
set.}
}
}
\description{
Get train/test splits of the phenotypic MET dataset based on a
number of random k-folds partitions determined by the user, according to the
type CV1. Creation of the list of train/test splits based on phenotypic data,
so that all the phenotypes from the same line appear in same fold (prediction
of new lines never observed in any environment).
}
\references{
\insertRef{jarquin2017increasing}{learnMET}
\insertRef{jarquin2014reaction}{learnMET}
}
\author{
Cathy C. Westhues \email{cathy.jubin@hotmail.com}
}
