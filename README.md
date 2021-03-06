
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dynamite

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/santikka/dynamite/workflows/R-CMD-check/badge.svg)](https://github.com/santikka/dynamite/actions)
[![Codecov test
coverage](https://codecov.io/gh/santikka/dynamite/branch/main/graph/badge.svg)](https://app.codecov.io/gh/santikka/dynamite?branch=main)
<!-- badges: end -->

The `dynamite` [R](https://www.r-project.org/) package provides
easy-to-use interface for Bayesian inference of complex panel (time
series) data comprising of multiple measurements per multiple
individuals measured in time. The main features distinguishing the
package and the underlying methodology from many other approaches are:

-   Support for both time-invariant and time-varying effects modeled via
    B-splines.
-   Joint modeling of multiple measurements per individual (multiple
    channels) based directly on the assumed data generating process.
-   Support for non-Gaussian observations: Currently Gaussian,
    Categorical, Poisson, Bernoulli, Binomial, Negative Binomial, Gamma,
    Exponential, and Beta distributions are available and these can be
    mixed arbitrarily in multichannel models.
-   Allows evaluating realistic long-term counterfactual predictions
    which take into account the dynamic structure of the model by
    posterior predictive distribution simulation.
-   Transparent quantification of parameter and predictive uncertainty
    due to a fully Bayesian approach.
-   User-friendly and efficient R interface with state-of-the-art
    estimation via Stan.

The `dynamite` package is developed with the support of Academy of
Finland grant 331817 ([PREDLIFE](https://sites.utu.fi/predlife/en/)).

## Installation

`dynamite` uses R’s native pipe operator, so R version 4.1.0 or newer is
required.

`dynamite` also relies on some of the features of
[Stan](https://mc-stan.org/)’s which are not yet available on the
[CRAN](https://cran.r-project.org/) version of
[rstan](https://CRAN.R-project.org/package=rstan) pacakge. Therefore you
need to install latest `rstan` and `StanHeaders` packages as

``` r
# run the next line if you already have rstan installed:
# remove.packages(c("StanHeaders", "rstan"))
install.packages("rstan", repos = c("https://mc-stan.org/r-packages/", 
  getOption("repos")))
```

(See more help on [RStan
wiki](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started))

Finally, a version `1.14.3` or newer of the
[data.table](https://github.com/Rdatatable/data.table) package is
required, which can be installed as

``` r
# run the next line if you do not have any version of the data.table installed:
#install.packages("data.table")

# install the latest development version:
data.table::update.dev.pkg()
```

After these steps, you can install the development version of dynamite
from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("santikka/dynamite")
```

## Example

A single-channel model with time-invariant effect of `z`, time-varying
effect of `x`, lagged value of the response variable `y` and a
group-specific random intercepts:

``` r
set.seed(1)
library(dynamite)
gaussian_example_fit <- dynamite(
  obs(y ~ -1 + z + varying(~ x + lag(y)), family = "gaussian") + 
    random() + splines(df = 20),
  data = gaussian_example, time = "time", group = "id",
  iter = 2000, warmup = 1000, thin = 5,
  chains = 2, cores = 2, refresh = 0, save_warmup = FALSE
)
```

Posterior estimates of the fixed effects:

``` r
plot_betas(gaussian_example_fit)
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="80%" />

Posterior estimates of time-varying effects

``` r
plot_deltas(gaussian_example_fit, scales = "free")
#> Warning: Removed 1 row(s) containing missing values (geom_path).
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="80%" />

And group-specific intercepts:

``` r
plot_nus(gaussian_example_fit)
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="80%" />

Traceplots and density plots:

``` r
plot(gaussian_example_fit, type = "beta")
```

<img src="man/figures/README-unnamed-chunk-10-1.png" width="80%" />

Posterior predictive samples for first 4 groups (samples based on the
posterior distribution of model parameters and observed data on first
time point):

``` r
library(ggplot2)
#> Warning: package 'ggplot2' was built under R version 4.1.3
pred <- predict(gaussian_example_fit, n_draws = 50)
pred |> dplyr::filter(id < 5) |> 
  ggplot(aes(time, y_new, group = draw)) +
  geom_line(alpha = 0.5) + 
  # observed values
  geom_line(aes(y = y), colour = "tomato") +
  facet_wrap(~ id) +
  theme_bw()
```

<img src="man/figures/README-unnamed-chunk-11-1.png" width="80%" />

For more examples, see the package vignette.

## Related packages

-   The `dynamite` package uses Stan via
    [`rstan`](https://CRAN.R-project.org/package=rstan) (see also
    <https://mc-stan.org>), which is a probabilistic programming
    language for general Bayesian modelling.

-   The [`brms`](https://CRAN.R-project.org/package=brms) package also
    uses Stan, and can be used to fit various complex multilevel models.

-   Regression modelling with time-varying coefficients based on kernel
    smoothing and least squares estimation is available in package
    [`tvReg`](https://CRAN.R-project.org/package=tvReg). The
    [`tvem`](https://CRAN.R-project.org/package=tvem) package provides
    similar functionality for gaussian, binomial and poisson responses
    with [`mgcv`](https://CRAN.R-project.org/package=mgcv) backend.

-   [`plm`](https://CRAN.R-project.org/package=plm) contains various
    methods to estimate linear models for panel data, e.g. the fixed
    effect models.

-   [`lavaan`](https://CRAN.R-project.org/package=lavaan) provides tools
    for structural equation modelling, and as such can be used to model
    various panel data models as well.
