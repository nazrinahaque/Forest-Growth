# ============================================================
# DISTURBANCE RISK AND LAND VALUE — CANAY (2011) QUANTILE FE
# Author: Nazrina Haque
# Description: 2-step quantile fixed effects estimator
#              with bootstrapped standard errors
# ============================================================

library(tidyverse)
library(fixest)
library(quantreg)

df     <- read.csv("hurricane_timberland_clean.csv")
df_reg <- df[df$year >= 2014, ]
df_reg <- panel(df_reg, ~county + year)

# ============================================================
# CANAY (2011) FUNCTION
# ============================================================
canay_quantile_fe <- function(data, formula_fe, formula_qr, quantile = 0.5) {

  # Step 1 — Linear FE to extract county effects
  fe_model  <- feols(formula_fe, data = data, vcov = "HC1")
  county_fe <- fixef(fe_model)$county[as.character(data$county)]

  # Step 2 — Remove FE from outcome
  data$logprice_FE <- data$lperacresale - county_fe

  # Step 3 — Quantile regression on adjusted outcome
  qr_model <- rq(formula_qr, data = data, tau = quantile)
  return(qr_model)
}

# ============================================================
# CANAY: NDVI DISTURBANCE (Median — tau = 0.5)
# ============================================================
cat("\n=== QUANTILE FE: NDVI Disturbance (tau = 0.5) ===\n")

fe_formula_ndvi <- lperacresale ~ michael_ndvi + michael_ndvi:afterpolicy +
                   michaelnot_ndvi + michaelnot_ndvi:afterpolicy +
                   other_hurricane_hit + other_hurricane_hit:afterpolicy +
                   di + elevation + mtemp + pi + precip +
                   vpdmax + vpdmin + near_dist_roads + near_dist_urban | county + year

qr_formula_ndvi <- logprice_FE ~ michael_ndvi + michael_ndvi:afterpolicy +
                   michaelnot_ndvi + michaelnot_ndvi:afterpolicy +
                   other_hurricane_hit + other_hurricane_hit:afterpolicy +
                   di + elevation + mtemp + pi + precip +
                   vpdmax + vpdmin + near_dist_roads + near_dist_urban + factor(year)

qfe_ndvi <- canay_quantile_fe(df_reg, fe_formula_ndvi, qr_formula_ndvi, quantile = 0.5)

# Bootstrap standard errors
set.seed(10101)
boot_ndvi <- boot.rq(
  model.matrix(qr_formula_ndvi, data = df_reg),
  df_reg$logprice_FE,
  tau = 0.5, R = 100
)
summary(qfe_ndvi)

# Percent effects on land value
cat("\nPercent effects on land value:\n")
cat("  Michael + NDVI damage (pre-2020): ",
    round((exp(coef(qfe_ndvi)["michael_ndvi"]) - 1) * 100, 2), "%\n")
cat("  Michael no NDVI damage (pre-2020):",
    round((exp(coef(qfe_ndvi)["michaelnot_ndvi"]) - 1) * 100, 2), "%\n")

# ============================================================
# CANAY: FIA DAMAGE DATA (20th percentile — tau = 0.2)
# ============================================================
cat("\n=== QUANTILE FE: FIA Forest Damage (tau = 0.2) ===\n")

fe_formula_dmg <- lperacresale ~ michaeldamaged + michaeldamaged:afterpolicy +
                  michaelnotdamaged + michaelnotdamaged:afterpolicy +
                  other_hurricane_hit + di + elevation + mtemp + pi +
                  precip + vpdmax + vpdmin +
                  near_dist_roads + near_dist_urban | county + year

qr_formula_dmg <- logprice_FE ~ michaeldamaged + michaeldamaged:afterpolicy +
                  michaelnotdamaged + michaelnotdamaged:afterpolicy +
                  other_hurricane_hit + di + elevation + mtemp + pi +
                  precip + vpdmax + vpdmin +
                  near_dist_roads + near_dist_urban + factor(year)

qfe_dmg <- canay_quantile_fe(df_reg, fe_formula_dmg, qr_formula_dmg, quantile = 0.2)

set.seed(10101)
boot_dmg <- boot.rq(
  model.matrix(qr_formula_dmg, data = df_reg),
  df_reg$logprice_FE,
  tau = 0.2, R = 300
)
summary(qfe_dmg)

cat("\nPercent effects on land value:\n")
cat("  Michael + forest damage (pre-2020):  ",
    round((exp(coef(qfe_dmg)["michaeldamaged"]) - 1) * 100, 2), "%\n")
cat("  Michael no forest damage (pre-2020): ",
    round((exp(coef(qfe_dmg)["michaelnotdamaged"]) - 1) * 100, 2), "%\n")

cat("\n✅ All quantile regressions complete!\n")
