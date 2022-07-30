rm(list=ls())
library(here)
source(here('settings.R'))# 상위 디렉토리에 있는 settings를 불러옵니다.
source(here("utils.R"))

############################################# stage 2 ########################################
# central_environment
# input : 1) total_models(모든 기관), 2) Z1Z2 data(local)
# output : loss Matrix(local)

# 경로 설정.
stage2_path = here('stage2')
input_path = here(stage2_path,'input/')
output_path = here(stage2_path,'output/')

# total_model 로드
total_models <- load_files(pattern="lasso_total_model_",path=input_path, as_list=T)
n_F <- ncol(total_models[[1]])

# Z1Z2 로드

# load_files(pattern=Z1Z2List, path="input/", as_list=FALSE)
Z1Z2List <- glue("lasso_Z1Z2_{name}.rds")
Z1Z2List <- readRDS(glue(input_path,Z1Z2List))

print('successfully loaded Z1Z2 list')

# 2. make loss matrix in local party
match_and_get_all_pair <- function(model_matrix, z2_list=Z1Z2List[[2]], num_it=n_I){
  # "this function matches the i-th model of a given institution 
  #  to a local i-th test data "
  
  match_return_pair<- function(i){
    ith_model <- model_matrix[i, 1:n_F]
    local_ith_test_data <- z2_list[[i]]
    return(list(local_ith_test_data, ith_model))
  }
  return(lapply(c(1:num_it), match_return_pair))
}

# make every pair for every model and data
every_pairs <- lapply(total_models, match_and_get_all_pair)


# 2. define loss function 
loss_function <- function(data, beta) {
  # calculate loss. divided into two sections. Left term and the Right term
  Y <- data %>% select(Y)
  
  Xdata <- data %>% select(-Y)
  intercept <- rep(1,nrow(Xdata))
  Xdata <- cbind(intercept, Xdata)
  
  # calculate logistic term
  logistic <- 1/(1+exp((-1)*(Xdata %>% as.matrix()) %*% beta))
  logistic <- Y %>% cbind(exp = logistic)
  #Y=1이면 그대로, Y가 0이면 1-되게
  correct_prob <- mapply(function(y,logit) {ifelse(y==1,logit,1-logit)},logistic$Y, logistic$exp)
  correct_prob <- mapply(function(y) {ifelse(y==0,1e-323,y)}, correct_prob)
  loss_sum <- sum(-log(correct_prob))
  

  return(loss_sum)
}

# 3. make loss Matrix (loss는 test data로 계산한다.)
send_data_and_beta<- function(every_pairs_list){
  lapply(every_pairs_list, function(x) lapply(x, function(x) loss_function(x[[1]],x[[2]])))
}

allLossList <- send_data_and_beta(every_pairs)
lossMatrix <- allLossList %>% do.call(cbind,.)

saveRDS(lossMatrix, file = here('stage2/output',glue("lasso_lossMatrix_{name}.rds")))
saveRDS(lossMatrix, file = here('stage3/input',glue("lasso_lossMatrix_{name}.rds")))

print('=============================================================================================================')
print('stage 2 is finished successfully. 단계 2가 성공적으로 종료되었습니다')
print(glue('output폴더에 lossMatrix_{name}.Rds를 이메일로 보내주십시오'))
print("=============================================================================================================")
