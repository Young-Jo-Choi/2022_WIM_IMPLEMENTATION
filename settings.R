require(repr)
# require(reshape)
require(glmnet)
# require(zoo)
require(glue)
require(tidyverse)
require(here)

# name <- switch("NCC", #여기에 해당하는 기관의 이름을 적어주시면 됩니다. 예시 : "SEV"
#     "SEV" = "H1",
#     "NCC" = "H2",
#     "SMC" = "H3",
#     "SNH" = "H4",
#     "AMC" = "H5"
# )
name <- 'Acetaminophen_ExtraTrees_gangnam_train'

# original_file_name <- "original_file_SEV.csv" # 기관에서 생산된 WICOX 시작 전 가장 초기 raw file. stage1 input에서 사용된다.
file_name <- glue("{name}.csv")

n_I <- 200 # iteration 숫자. 현재는 200번으로 통일합니다.
n_H <- 2 # 참여 기관수


# 제외할 특성을 기록해주십시오. 
except_features = c()
# 종속변수를 기록해주십시오.
y = "label"


# print settings
print(glue("the name of the institution is {name}"))
print(glue("number of institution is {n_H}"))
print(glue("number of iteration is {n_I}"))



