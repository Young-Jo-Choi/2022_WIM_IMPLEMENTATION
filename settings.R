require(repr)
require(glmnet)
require(glue)
require(dplyr)
require(here)

args <- commandArgs(trailingOnly = TRUE)
insti <- args[1]
drug <- args[2]

method <- 'ExtraTrees'
name <- glue('{drug}_{insti}_{method}_train')
name_val <- glue('{drug}_{insti}_{method}_val')

file_name <- glue("{name}.csv")
file_name_val <- glue("{name_val}.csv")

n_I <- 200 # iteration 숫자. 현재는 200번으로 통일합니다.
n_H <- 3 # 참여 기관수


# 제외할 특성을 기록해주십시오. 
except_features = c('person_id','cohort_start_date')
# 종속변수를 기록해주십시오.
y = "label"


# print settings
print(glue("the name of the training file is {name}"))
print(glue("number of institution is {n_H}"))
print(glue("number of iteration is {n_I}"))

