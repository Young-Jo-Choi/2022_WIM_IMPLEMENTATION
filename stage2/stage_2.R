rm(list=ls())
source('settings.R') # 상위 디렉토리에 있는 settings를 불러옵니다.
source("utils.R")
############################################# stage 2 ########################################
# central_environment
# input : 1) loss_models(모든 기관), 2) Z1Z2 data(local), 3)lasso logistic, xgb model(모든 기관)
# output : 1) loss Matrix, 2) predictions by all models

set.seed(2022)

# insti <- 'konyang'
# drug <- 'Acetaminophen'
# 
# method <- 'ExtraTrees'
# name <- glue('{drug}_{insti}_{method}_train')
# name_val <- glue('{drug}_{insti}_{method}_val')
# 
# file_name <- glue("{name}.csv")
# file_name_val <- glue("{name_val}.csv")

# 경로 설정.
stage1_path = 'stage1'
stage2_path = 'stage2'
stage1_output_path = glue('{stage1_path}/output/')
input_path = glue('{stage2_path}/input/')
output_path = glue('{stage2_path}/output/')



load_files <- function(pattern, path, as_list = FALSE) {
  require(dplyr)
  
  # as list true일 경우 2개 이상의 데이터를 한번에 리스트로 불러온다.
  fileLists <- list.files(path)
  files <- fileLists[grep(pattern, fileLists)]
  print(glue("files are {files}"))
  full_path <- files %>% purrr::map_chr(~ paste0(input_path, .x))
  # full_path <- files %>% purrr::map_chr(~ here(path, .))
  mapply(function(x, y) assign(stringr::str_sub(y, length(y), -5), readRDS(x), envir = globalenv()), full_path, files)
  
  if (as_list == TRUE) {
    wanted_list <- list()
    allVariables <- ls(.GlobalEnv)
    wanted_names <- allVariables[grep(pattern, allVariables)]
    print(wanted_names)
    print(glue("length of this list is : {length(wanted_names)}"))
    
    for (f in 1:length(wanted_names)) {
      wanted_list[[f]] <- get(wanted_names[[f]])
    }
    return(wanted_list)
  } else {
    return(readRDS(full_path))
  }
}

# total_model 로드
total_models <- load_files(pattern=glue("lasso_loss_model_{drug}"),path=input_path, as_list=T)
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
  Y <- data %>% dplyr::select(Y)
  
  Xdata <- data %>% dplyr::select(-Y)
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

saveRDS(lossMatrix, file = glue("stage2/output/lasso_lossMatrix_{name}.rds"))
saveRDS(lossMatrix, file = glue("stage3/input/lasso_lossMatrix_{name}.rds"))

# 
# 모델 load(신촌,강남,건양대)
sinchon_model <- readRDS(glue(input_path,'models_{drug}_sinchon_{method}_train_fit.rds'))
gangnam_model <- readRDS(glue(input_path,'models_{drug}_gangnam_{method}_train_fit.rds'))
konyang_model <- readRDS(glue(input_path,'models_{drug}_konyang_{method}_train_fit.rds'))

# 각 모델로 평가, lasso라는 네이밍은 고치기
train <- readRDS(glue(stage1_output_path,'{name}_changed.rds'))
val <- readRDS(glue(stage1_output_path,'{name_val}_changed.rds'))

assign(paste0(insti,'_train_predict_sinchon_lasso'), predict(sinchon_model[[1]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_sinchon_lasso'), predict(sinchon_model[[1]], as.matrix(val[,-c(1)]), type='response'))
assign(paste0(insti,'_train_predict_gangnam_lasso'), predict(gangnam_model[[1]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_gangnam_lasso'), predict(gangnam_model[[1]], as.matrix(val[,-c(1)]), type='response'))
assign(paste0(insti,'_train_predict_konyang_lasso'), predict(konyang_model[[1]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_konyang_lasso'), predict(konyang_model[[1]], as.matrix(val[,-c(1)]), type='response'))

assign(paste0(insti,'_train_predict_sinchon_xgb'), predict(sinchon_model[[2]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_sinchon_xgb'), predict(sinchon_model[[2]], as.matrix(val[,-c(1)]), type='response'))
assign(paste0(insti,'_train_predict_gangnam_xgb'), predict(gangnam_model[[2]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_gangnam_xgb'), predict(gangnam_model[[2]], as.matrix(val[,-c(1)]), type='response'))
assign(paste0(insti,'_train_predict_konyang_xgb'), predict(konyang_model[[2]], as.matrix(train[,-c(1)]), type='response'))
assign(paste0(insti,'_val_predict_konyang_xgb'), predict(konyang_model[[2]], as.matrix(val[,-c(1)]), type='response'))


command1 <- paste0("save(",insti,"_train_predict_sinchon_lasso,",
                   insti,"_train_predict_gangnam_lasso,",
                   insti,"_train_predict_sinchon_xgb,",
                   insti,"_train_predict_gangnam_xgb,",
                   "file='stage2/output/",drug,"_",insti,"_train_predict.RData')")
command2 <- paste0("save(",insti,"_val_predict_sinchon_lasso,",
                   insti,"_val_predict_gangnam_lasso,",
                   insti,"_val_predict_sinchon_xgb,",
                   insti,"_val_predict_gangnam_xgb,",
                   "file='stage2/output/",drug,"_",insti,"_val_predict.RData')")
eval(parse(text=command1))
eval(parse(text=command2))

command1 <- paste0("save(",insti,"_train_predict_sinchon_lasso,",
                   insti,"_train_predict_gangnam_lasso,",
                   insti,"_train_predict_konyang_lasso,",
                   insti,"_train_predict_sinchon_xgb,",
                   insti,"_train_predict_gangnam_xgb,",
                   insti,"_train_predict_konyang_xgb,",
                   "file='stage2/output/",drug,"_",insti,"_train_predict.RData')")
command2 <- paste0("save(",insti,"_val_predict_sinchon_lasso,",
                   insti,"_val_predict_gangnam_lasso,",
                   insti,"_val_predict_konyang_lasso,",
                   insti,"_val_predict_sinchon_xgb,",
                   insti,"_val_predict_gangnam_xgb,",
                   insti,"_val_predict_konyang_xgb,",
                   "file='stage2/output/",drug,"_",insti,"_val_predict.RData')")
# 
eval(parse(text=command1))
eval(parse(text=command2))

# #임시
# load('stage2/output/Olmesartan_gangnam_val_predict.RData')
# pred <- gangnam_val_predict_sinchon_lasso
# real <- readRDS('stage1/output/Olmesartan_gangnam_val_label.rds')
# acc_auc(real, pred)
list.files(path='stage2/input')
# #

print('=============================================================================================================')
print('stage 2 is finished successfully. 단계 2가 성공적으로 종료되었습니다')
print("=============================================================================================================")
