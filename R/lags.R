#' Add Lagged Responses as Predictors to Each Channel of a Dynamite Model
#'
#' @param k \[`integer()`: \sQuote{1}]\cr
#'   Values lagged by `k` units of time of each observed response variable
#'   will be added as a predictor for each channel. Should be a positive
#'   (unrestricted) integer.
#' @param type \[`integer(1)`: \sQuote{"fixed"}]\cr Either
#'   `"fixed"` or `"varying"` which indicates whether the coefficients of the
#'   added lag terms should vary in time or not.
#' @return A object of class `lags`.
#' @export
#' @examples
#' obs(y ~ -1 + varying(~x), family = "gaussian") +
#'   lags(type = "varying") + splines(df = 20)
#'
#' @srrstats {G2.3a} Uses match.arg
lags <- function(k = 1L, type = c("fixed", "varying")) {
  type <- onlyif(is.character(type), tolower(type))
  type <- try(match.arg(type, c("fixed", "varying")), silent = TRUE)
  stopifnot_(
    !"try-error" %in% class(type),
    "Argument {.arg type} must be \"fixed\" or \"varying\"."
  )
  stopifnot_(
    checkmate::test_integerish(
      x = k,
      lower = 1L,
      any.missing = FALSE,
      min.len = 1L,
      unique = TRUE,
    ),
    "Argument {.arg k} must be an {.cls integer} vector with positive values."
  )
  structure(
    list(k = as.integer(k), type = type),
    class = "lags"
  )
}

#' Is the Argument a `lags` Definition
#'
#' @param x An R object
#' @noRd
is.lags <- function(x) {
  inherits(x, "lags")
}

#' Create a Lagged Version of a Vector
#'
#' @param x \[`vector()`]\cr A vector of values.
#' @param k \[`integer(1)`: \sQuote{1}]\cr Number of positions to lag by.
#' @noRd
lag_ <- function(x, k = 1) {
  lag_idx <- seq_len(length(x) - k)
  out <- x
  out[seq_len(k)] <- NA
  out[k + lag_idx] <- x[lag_idx]
  out
}

#' Adds default shift values to terms of the form lag(y)
#'
#' @param x A `language` object.
#' @noRd
complete_lags <- function(x) {
  if (identical(length(x), 1L)) {
    return(x)
  }
  if (identical(deparse1(x[[1]]), "lag")) {
    xlen <- length(x)
    if (identical(xlen, 2L)) {
      x <- str2lang(
        paste0("lag(", deparse1(x[[2L]]), ", ", "1)")
      )
    } else if (identical(xlen, 3L)) {
      k <- verify_lag(x[[3L]], deparse1(x))
      x <- str2lang(
        paste0("lag(", deparse1(x[[2L]]), ", ", k, ")")
      )
    } else {
      stop_(c(
        "Invalid lag definition {.code {deparse1(x)}}:",
        `x` = "Too many arguments supplied to {.fun lag}."
      ))
    }
  } else {
    for (i in seq_along(x)) {
      x[[i]] <- complete_lags(x[[i]])
    }
  }
  x
}

#' Find Lag Terms in a Character Vector
#'
#' @param x \[`character()`]\cr A character vector.
#' @noRd
find_lags <- function(x) {
  grepl("lag\\([^\\)]+\\)", x, perl = TRUE)
}

#' Extract Non-lag Variables
#'
#' @param x \[`character(1)`]\cr A character vector.
#' @noRd
extract_nonlags <- function(x) {
  x[!find_lags(x)]
}

#' Extract Lag Definitions
#'
#' Extract variables and shifts of lagged terms of the form `lag(var, k)`
#' and return them as a data frame for post processing.
#'
#' @param x \[`character()`]\cr a character vector.
#' @noRd
extract_lags <- function(x) {
  has_lag <- find_lags(x)
  if (any(has_lag)) {
    lag_terms <- paste0(x[has_lag], " ")
  } else {
    lag_terms <- character(0)
  }
  lag_regex <- gregexec(
    pattern = paste0(
      "(?<src>lag\\((?<var>[^\\+\\)\\,]+?)",
      "(?:,\\s*(?<k>[0-9]+)){0,1}\\))"
    ),
    text = lag_terms,
    perl = TRUE
  )
  lag_matches <- regmatches(lag_terms, lag_regex)
  if (length(lag_matches) > 0L) {
    lag_map <- do.call("cbind", args = lag_matches)
    lag_map <- as.data.frame(t(lag_map)[, -1L, drop = FALSE])
    lag_map$k <- as.integer(lag_map$k)
    lag_map$k[is.na(lag_map$k)] <- 1L
    lag_map$present <- TRUE
    lag_map |>
      dplyr::distinct() |>
      dplyr::group_by(.data$var) |>
      tidyr::complete(k = tidyr::full_seq(c(1L, .data$k), 1L),
                      fill = list(src = "", present = FALSE)) |>
      dplyr::arrange(.data$var, .data$k) |>
      dplyr::ungroup()
  } else {
    data.frame(
      src = character(0L),
      var = character(0L),
      k = integer(0L),
      present = logical(0L)
    )
  }
}

#' Verify that `k` in `lag(y, k)` represents a valid shift value expression
#'
#' @param k The shift value definition as a `language` object.
#' @param lag_str The full lag term definition as a `character` string.
#' @noRd
verify_lag <- function(k, lag_str) {
  k_str <- deparse1(k)
  k_coerce <- try(eval(k), silent = TRUE)
  if ("try-error" %in% class(k_coerce)) {
    stop_("Invalid shift value expression {.code {k_str}}.")
  }
  k_coerce <- tryCatch(
    expr = as.integer(k_coerce),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  if (is.null(k_coerce) ||
      identical(length(k_coerce), 0L) ||
      any(is.na(k_coerce))) {
    stop_(
      "Unable to coerce shift value to {.cls integer} in {.code {lag_str}}."
    )
  }
  if (length(k_coerce) > 1L) {
    stop_(c(
      "Shift value must be a single {.cls integer} in {.fun lag}:",
      `x` = "Multiple shift values were found in {.code {lag_str}}."
    ))
  }
  if (k_coerce <= 0L) {
    stop_(c(
      "Shift value must be positive in {.fun lag}:",
      `x` = "Nonpositive shift value was found in {.code {lag_str}}."
    ))
  }
  k_coerce
}

#' Extract Lag Shift Values of a Specific Variable from a Character String
#'
#' @param x \[`character(1)`]\cr String to search for lag definitions.
#' @param self \[`character(1)`]\cr Variable whose lags to look for.
#' @noRd
extract_self_lags <- function(x, self) {
  lag_regex <-  gregexec(
    pattern = paste0(
      "lag\\(", self, ",\\s*(?<k>.+?)\\s*\\)"
    ),
    text = x,
    perl = TRUE
  )
  lag_matches <- regmatches(x, lag_regex)[[1]]
  if (length(lag_matches) > 0L) {
    as.integer(lag_matches["k", ])
  } else {
    0L
  }
}
