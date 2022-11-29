rm(list=ls())
source("utils.R")
require(glue)

args <- commandArgs(trailingOnly = TRUE)
drug <- args[1]

# drug <- 'Naproxen'
n_I <- 200 # iteration 숫자. 현재는 200번으로 통일합니다.
n_H <- 3 # 참여 기관수

########################################## stage 3 #############################################
# central environment
# input : 1) loss Matrix(모든기관), 2) lasso logistic, xgb model(모든 기관), 3) label 정보
# output : 1) WIM_standard_weights, 2)evaluation
# 각 기관의 loss를 모은다.

set.seed(2022)

# 경로 설정
stage3_path <- "stage3/"
input_path <- glue("{stage3_path}/input/")
output_path <- glue("{stage3_path}/output/")

# 기본 변수 설정 로딩해줘야 함.

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
# loss matrix를 리스트 형태로 데려온다. 그리고 total loss 계산
allLossMatrices <- load_files(paste0("lasso_lossMatrix_",drug),input_path, as_list=TRUE)

turn2numeric <- lapply(allLossMatrices, function(x) mapply(x, FUN=as.numeric))
reconstructed_allLossMatrices <- lapply(turn2numeric, function(x) matrix(x, nrow=n_I, ncol=n_H))

total_loss <- Reduce('+', reconstructed_allLossMatrices)

total_loss_i <- 1 / total_loss

# 여기는 standard weight에 해당함
standard_weights <- total_loss_i %>% apply(1,function(x) x/sum(x)) %>% t


# 여기서부터 수정
# 1,2,3이 강남,신촌,건양인지 강남,건양,신촌인지 구분
weight_mean <- apply(standard_weights,2,mean)
# 라벨 load
gangnam_train_label <- as.matrix(readRDS(glue('stage1/output/{drug}_gangnam_train_label.rds')))
sinchon_train_label <- as.matrix(readRDS(glue('stage1/output/{drug}_sinchon_train_label.rds')))
konyang_train_label <- as.matrix(readRDS(glue('stage1/output/{drug}_konyang_train_label.rds')))

gangnam_val_label <- as.matrix(readRDS(glue('stage1/output/{drug}_gangnam_val_label.rds')))
sinchon_val_label <- as.matrix(readRDS(glue('stage1/output/{drug}_sinchon_val_label.rds')))
konyang_val_label <- as.matrix(readRDS(glue('stage1/output/{drug}_konyang_val_label.rds')))

entire_train_label <- as.matrix(c(gangnam_train_label,konyang_train_label, sinchon_train_label))
entire_val_label <- as.matrix(c(gangnam_val_label,konyang_val_label, sinchon_val_label))

# 예측 load
load(glue('stage2/output/{drug}_gangnam_train_predict.RData'))
load(glue('stage2/output/{drug}_sinchon_train_predict.RData'))
load(glue('stage2/output/{drug}_gangnam_val_predict.RData'))
load(glue('stage2/output/{drug}_sinchon_val_predict.RData'))
load(glue('stage2/output/{drug}_konyang_train_predict.RData'))
load(glue('stage2/output/{drug}_konyang_val_predict.RData'))


gangnam_train_predict_wim_lasso <- gangnam_train_predict_gangnam_lasso*weight_mean[1]+
                                    gangnam_train_predict_konyang_lasso*weight_mean[2]+
                                    gangnam_train_predict_sinchon_lasso*weight_mean[3]
konyang_train_predict_wim_lasso <- konyang_train_predict_gangnam_lasso*weight_mean[1]+
                                    konyang_train_predict_konyang_lasso*weight_mean[2]+
                                   konyang_train_predict_sinchon_lasso*weight_mean[3]
sinchon_train_predict_wim_lasso <- sinchon_train_predict_gangnam_lasso*weight_mean[1]+
                                    sinchon_train_predict_konyang_lasso*weight_mean[2]+
                                    sinchon_train_predict_sinchon_lasso*weight_mean[3]
                                    
gangnam_val_predict_wim_lasso <- gangnam_val_predict_gangnam_lasso*weight_mean[1]+
                                  gangnam_val_predict_konyang_lasso*weight_mean[2]+
                                  gangnam_val_predict_sinchon_lasso*weight_mean[3]
konyang_val_predict_wim_lasso <- konyang_val_predict_gangnam_lasso*weight_mean[1]+
                                  konyang_val_predict_konyang_lasso*weight_mean[2]+
                                  konyang_val_predict_sinchon_lasso*weight_mean[3]
sinchon_val_predict_wim_lasso <- sinchon_val_predict_gangnam_lasso*weight_mean[1]+
                                  sinchon_val_predict_konyang_lasso*weight_mean[2]+
                                  sinchon_val_predict_sinchon_lasso*weight_mean[3]
                                  
gangnam_train_predict_wim_xgb <- gangnam_train_predict_gangnam_xgb*weight_mean[1]+
                                  gangnam_train_predict_konyang_xgb*weight_mean[2]+
                                  gangnam_train_predict_sinchon_xgb*weight_mean[3]
konyang_train_predict_wim_xgb <- konyang_train_predict_gangnam_xgb*weight_mean[1]+
                                  konyang_train_predict_konyang_xgb*weight_mean[2]+
                                  konyang_train_predict_sinchon_xgb*weight_mean[3]
sinchon_train_predict_wim_xgb <- sinchon_train_predict_gangnam_xgb*weight_mean[1]+
                                  sinchon_train_predict_konyang_xgb*weight_mean[2]+
                                  sinchon_train_predict_sinchon_xgb*weight_mean[3]

gangnam_val_predict_wim_xgb <- gangnam_val_predict_gangnam_xgb*weight_mean[1]+
                                  gangnam_val_predict_konyang_xgb*weight_mean[2]+
                                  gangnam_val_predict_sinchon_xgb*weight_mean[3]
konyang_val_predict_wim_xgb <- konyang_val_predict_gangnam_xgb*weight_mean[1]+
                                konyang_val_predict_konyang_xgb*weight_mean[2]+
                                konyang_val_predict_sinchon_xgb*weight_mean[3]
sinchon_val_predict_wim_xgb <- sinchon_val_predict_gangnam_xgb*weight_mean[1]+
                                  sinchon_val_predict_konyang_xgb*weight_mean[2]+
                                  sinchon_val_predict_sinchon_xgb*weight_mean[3]

entire_train_predict_gangnam_lasso <- c(gangnam_train_predict_gangnam_lasso,
                                        konyang_train_predict_gangnam_lasso,
                                        sinchon_train_predict_gangnam_lasso)
entire_val_predict_gangnam_lasso <- c(gangnam_val_predict_gangnam_lasso,
                                      konyang_val_predict_gangnam_lasso,
                                      sinchon_val_predict_gangnam_lasso)
entire_train_predict_sinchon_lasso <- c(gangnam_train_predict_sinchon_lasso,
                                        konyang_train_predict_sinchon_lasso,
                                        sinchon_train_predict_sinchon_lasso)
entire_val_predict_sinchon_lasso <- c(gangnam_val_predict_sinchon_lasso,
                                      konyang_val_predict_sinchon_lasso,
                                      sinchon_val_predict_sinchon_lasso)
entire_train_predict_konyang_lasso <- c(gangnam_train_predict_konyang_lasso,
                                        konyang_train_predict_konyang_lasso,
                                        sinchon_train_predict_konyang_lasso)
entire_val_predict_konyang_lasso <- c(gangnam_val_predict_konyang_lasso,
                                      konyang_val_predict_konyang_lasso,
                                      sinchon_val_predict_konyang_lasso)
entire_train_predict_wim_lasso <- c(gangnam_train_predict_wim_lasso,
                                    konyang_train_predict_wim_lasso,
                                    sinchon_train_predict_wim_lasso)
entire_val_predict_wim_lasso <- c(gangnam_val_predict_wim_lasso,
                                  konyang_val_predict_wim_lasso,
                                  sinchon_val_predict_wim_lasso)


entire_train_predict_gangnam_xgb <- c(gangnam_train_predict_gangnam_xgb,
                                      konyang_train_predict_gangnam_xgb,
                                      sinchon_train_predict_gangnam_xgb)
entire_val_predict_gangnam_xgb <- c(gangnam_val_predict_gangnam_xgb,
                                    konyang_val_predict_gangnam_xgb,
                                    sinchon_val_predict_gangnam_xgb)
entire_train_predict_sinchon_xgb <- c(gangnam_train_predict_sinchon_xgb,
                                      konyang_train_predict_sinchon_xgb,
                                      sinchon_train_predict_sinchon_xgb)
entire_val_predict_sinchon_xgb <- c(gangnam_val_predict_sinchon_xgb,
                                    konyang_val_predict_sinchon_xgb,
                                    sinchon_val_predict_sinchon_xgb)
entire_train_predict_konyang_xgb <- c(gangnam_train_predict_konyang_xgb,
                                      konyang_train_predict_konyang_xgb,
                                      sinchon_train_predict_konyang_xgb)
entire_val_predict_konyang_xgb <- c(gangnam_val_predict_konyang_xgb,
                                    konyang_val_predict_konyang_xgb,
                                    sinchon_val_predict_konyang_xgb)
entire_train_predict_wim_xgb <- c(gangnam_train_predict_wim_xgb,
                                  konyang_train_predict_wim_xgb,
                                  sinchon_train_predict_wim_xgb)
entire_val_predict_wim_xgb <- c(gangnam_val_predict_wim_xgb,
                                konyang_val_predict_wim_xgb,
                                sinchon_val_predict_wim_xgb)


institions <- c('gangnam','konyang','sinchon','wim')
models <- c('lasso','xgb')
for (model in models){
  for (insti in institions){
    assign(paste0(insti,"_",model,"_eval"),
           cbind(acc_auc(gangnam_train_label, eval(parse(text = paste0("gangnam_train_predict_",insti,"_",model)))),
                 acc_auc(gangnam_val_label, eval(parse(text = paste0("gangnam_val_predict_",insti,"_",model)))),
                 acc_auc(konyang_train_label, eval(parse(text = paste0("konyang_train_predict_",insti,"_",model)))),
                 acc_auc(konyang_val_label, eval(parse(text = paste0("konyang_val_predict_",insti,"_",model)))),
                 acc_auc(sinchon_train_label, eval(parse(text = paste0("sinchon_train_predict_",insti,"_",model)))),
                 acc_auc(sinchon_val_label, eval(parse(text = paste0("sinchon_val_predict_",insti,"_",model)))),
                 acc_auc(entire_train_label, as.matrix(eval(parse(text = paste0("entire_train_predict_",insti,"_",model))))),
                 acc_auc(entire_val_label, as.matrix(eval(parse(text = paste0("entire_val_predict_",insti,"_",model))))) 
                 ))
  }
}




# acc_auc(entire_val_label, eval(parse(text = paste0("entire_val_predict_",insti,"_",model))))
# min(eval(parse(text = paste0("entire_val_predict_",insti,"_",model))))
# entire_val_predict_gangnam_lasso


all_lasso_eval <- list(gangnam_lasso_eval, konyang_lasso_eval, sinchon_lasso_eval, wim_lasso_eval)
all_xgb_eval <- list(gangnam_xgb_eval,konyang_xgb_eval, sinchon_xgb_eval, wim_xgb_eval)
saveRDS(standard_weights, glue('{output_path}/{drug}_lasso_standard_weights_3insti.rds'))
saveRDS(all_lasso_eval, glue('{output_path}/{drug}_all_lasso_eval_3insti.rds'))
saveRDS(all_xgb_eval, glue('{output_path}/{drug}_all_xgb_eval_3insti.rds'))


print('==========================================================================================================================')
print('stage 3 is finished successfully. 단계 3이 성공적으로 종료되었습니다')
print(glue('output폴더에 standard_weights.rds와 {drug}_all_lasso_eval.rds, {drug}_all_xgb_eval.rds가 있는지 확인해주십시오.'))
print("==========================================================================================================================")
