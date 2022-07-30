rm(list=ls())
require(here)
source(here('settings.R'))
source(here("utils.R"))


########################################## stage 3 #############################################
# central environment
# input : 1) loss Matrix(모든기관), 2) total_models(모든 기관)
# output : 1) loss_WIM_para_VAR
# 각 기관의 loss를 모은다.

# 경로 설정
stage3_path <- here("stage3/")
input_path <- here(stage3_path, "input/")
output_path <- here(stage3_path, "output/")

# 기본 변수 설정 로딩해줘야 함.

# loss matrix를 리스트 형태로 데려온다. 그리고 total loss 계산
allLossMatrices <- load_files("lasso_lossMatrix",input_path, as_list=TRUE)

turn2numeric <- lapply(allLossMatrices, function(x) mapply(x, FUN=as.numeric))
reconstructed_allLossMatrices <- lapply(turn2numeric, function(x) matrix(x, nrow=n_I, ncol=n_H))

total_loss <- Reduce('+', reconstructed_allLossMatrices)

# total model 로딩 필요
total_models <- load_files("lasso_total_model_",input_path,as_list=TRUE)
n_F <- ncol(total_models[[1]])

total_loss_i <- 1 / total_loss

# 여기는 standard weight에 해당함
standard_weights <- total_loss_i %>% apply(1,function(x) x/sum(x)) %>% t

# 수정 필요
# 1. standard beta calculation
# each_W_mul_beta : shape : 200x2x6
each_W_mul_beta <- lapply(c(1:n_I), function(x) 
  lapply(c(1:n_H), function(y) 
    as.numeric(total_models[[y]][x,1:n_F] * standard_weights[x,y])))
# 각 모델 계수의 가중합
WIM_standard_beta <- lapply(each_W_mul_beta, Reduce, f='+') %>% do.call(rbind,.)

saveRDS(standard_weights, here(output_path,'lasso_standard_weights.rds'))
saveRDS(WIM_standard_beta, here(output_path,'lasso_WIM_standard_beta.rds'))

print('==========================================================================================================================')
print('stage 3 is finished successfully. 단계 3이 성공적으로 종료되었습니다')
print(glue('output폴더에 standard_weights.rds와 WIM_standard_beta.rds가 있는지 확인해주십시오.'))
print("==========================================================================================================================")

