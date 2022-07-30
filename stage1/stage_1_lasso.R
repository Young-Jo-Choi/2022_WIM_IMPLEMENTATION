rm(list=ls())
require(here)
source(here('settings.R'))
source(here("utils.R"))
########################################### stage 1 ####################################################
# local_environment
# input : 1) 기관_data.csv, common_columns.rds
# output : 1) changed data, 2) Z1Z2List, 3)total_model
#          4)each_model, 5)lambda parameter of total model,  6)lambda parameter of each model

# settings.R에서 초기값 설정이 필요합니다.
stage1_path <- here('stage1')

input_path <- here(stage1_path,'input')
output_path <- here(stage1_path,'output')

# 파일 읽어오기
df <- read.csv(here(input_path,file_name)) 

using_columns <- setdiff(colnames(df), except_features)
df <- df %>% select(using_columns)
# features + intercept (현재는 label이 대신 count되어 결과적으로는 같음)
n_F <- ncol(df)

print('df loaded')
df_changed <- namer_function(df)
saveRDS(df_changed, here(output_path, glue('lasso_{name}_changed.rds')))

# Z1과 Z2를 만든다.
Generate.Z1.Z2 <- function(local.data, predictor, m)
{   
  z1.list <- list()
  z2.list <- list()
  
  # 200번 분할, 0과 1비율 맞도록
  for(i in 1:m){
    local.data.Y0 <- filter(local.data, get(predictor)==0)
    local.data.Y1 <- filter(local.data, get(predictor)==1)
    Y0.n1 <- ceiling(nrow(local.data.Y0)/2)
    Y1.n1 <- ceiling(nrow(local.data.Y1)/2)
    n1 <- Y0.n1 + Y1.n1
    idx0<- sample(1:nrow(local.data.Y0),nrow(local.data.Y0),replace=FALSE)
    idx1<- sample(1:nrow(local.data.Y1),nrow(local.data.Y1),replace=FALSE)
    local.data.Y0 <- local.data.Y0[idx0,]
    local.data.Y1 <- local.data.Y1[idx1,]
    z1.Y0 <- local.data.Y0[1:Y0.n1,]
    z2.Y0 <- local.data.Y0[(Y0.n1+1):nrow(local.data.Y0),]
    z1.Y1 <- local.data.Y1[1:Y1.n1,]
    z2.Y1 <- local.data.Y1[(Y1.n1+1):nrow(local.data.Y1),]
    z1 <- rbind(z1.Y0, z1.Y1)
    z2 <- rbind(z2.Y0, z2.Y1)
    
    z1.list <- append(z1.list, list(z1))
    z2.list <- append(z2.list, list(z2))
  }
  
  return(list(z1.list, z2.list))
}
Z1Z2List<- Generate.Z1.Z2(df_changed, "Y",n_I)
saveRDS(Z1Z2List, file = here(output_path, glue("lasso_Z1Z2_{name}.rds")))
saveRDS(Z1Z2List, file = here("stage2/input", glue("lasso_Z1Z2_{name}.rds")))



# make local model and save
local_fit_cv <- cv.glmnet(x = as.matrix(df_changed[,-c(1)]),
                           y = as.matrix(df_changed[,'Y']), family = 'binomial',alpha=1)
local_fit <- glmnet(x = as.matrix(df_changed[,-c(1)]),
                    y = as.matrix(df_changed[,'Y']),
                    alpha=1, family="binomial",lambda=local_fit_cv$lambda.min )

saveRDS(local_fit, file=here(output_path, glue("lasso_{name}_fit.rds")))


# 모델을 만든다.
make_model <- function(z1z2list, party_name){
  m <- z1z2list[[1]] %>% length
  
  # 모델을 만든다. z1z2의 리스트에 있는 z1의 1~m개의 데이터를 바탕으로 모델을 만든다.
  # 모델의 이름은 glm.파티이름.i이다. i는 1~m번 iteration 하면서 적용된 수(m=n_I)
  
  for(i in 1:m){
    fitting_data <- as.data.frame(z1z2list[[1]][[i]])
    lasso_cv <- cv.glmnet(x = as.matrix(fitting_data[,-c(1)]),
                           y = fitting_data[,'Y'], family = 'binomial',alpha=1)
    assign(paste0('glm','.',party_name,'.',i), 
           glmnet(x = fitting_data[,-c(1)],
                  y = fitting_data[,'Y'],
                  alpha=1, family="binomial",lambda=lasso_cv$lambda.min),
           envir=.GlobalEnv)
          }
    }

make_model(Z1Z2List, name) # 모델이 메모리 상에 생성됨

# 각 lasso마다의 lambda를 저장
lambda.set <- c()
for (i in 1:n_I){
  lambda.selected <- get(paste0('glm.',name,'.',i))$lambda
  lambda.set <- c(lambda.set, lambda.selected)
}
lambda.set %>% saveRDS(file=here(output_path,glue('lasso_lambda_{name}.rds')))


# coefficient matrix를 만든다.
make_coefficient_matrix <- function(z1z2list, party_name)
{
  # 이 함수의 목적은 생성된 모델들의 beta를 가지는 행렬을 만든다.
  
  n_I <- z1z2list[[1]] %>% length # m은 반복횟수(iteration 횟수)
  n_F <- (z1z2list[[1]][[1]] %>% names %>% length) - 1 + 1 # feature수(종속변수는 제외, intercept 포함)
  
  # 각 데이터로부터의 행렬. m*p 모양이다
  total_model <- matrix(nrow=n_I, ncol=n_F)
  
  # 모델 리스트(벡터)
  model_list <- c()
  for( i in 1:n_I){
    model_list[i] <- paste0('glm.',party_name,'.',i)
  }
  
  # matrix 생성
  for(i in 1:n_I){
    for(j in 1:n_F){
      
      ij <- coef(get(model_list[i],envir=.GlobalEnv))[j]
      # 계수(beta) 저장
      total_model[i,j] <- ij
    }
  }
  
  # 데이터프레임을 반환
  return(assign(paste0('total_model_',party_name),total_model, envir=.GlobalEnv))
}

make_coefficient_matrix(Z1Z2List, name)
total_model <- get(glue('total_model_{name}'))
# intercept와 계수
total_model %>% saveRDS(file=here(output_path,glue('lasso_total_model_{name}.rds')))
total_model %>% saveRDS(file = here("stage2/input", glue("lasso_total_model_{name}.rds")))
