set.seed(1)
library(dynamite)
f <- obs(x ~ z + lag(x) + lag(y), family = "categorical") +
  obs(y ~ z + lag(x) + lag(y), family = "categorical")

categorical_example_fit <- dynamite(
  dformula = f,
  data = categorical_example,
  group = "id",
  time = "time",
  chains = 1,
  refresh = 0,
  thin = 5,
  save_warmup = FALSE
)

usethis::use_data(categorical_example_fit, overwrite = TRUE, compress = "xz")
