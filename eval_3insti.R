## AUROC, AUPRC
## 강남에 대하여, 신촌에 대하여, Range,Incidence
rm(list=ls())
require(glue)
require(pROC)
source('utils.R')

auc_eval <- function(y_label, y_pred){
  require(pROC)
  y_pred <- as.matrix(y_pred)
  if (min(y_pred)<0){
    y_pred_label <- apply(y_pred,1,ispositive_n_p)
  }else{
    y_pred_label <- apply(y_pred,1,ispositive_0_1)
  }
  # acc_value <- mean(y_pred_label==y_label)
  roc_value <- roc(y_label~y_pred,ci=T,quiet=T)
  auc_value <- roc_value$auc[1]
  lower <- roc_value$ci[1]
  upper <- roc_value$ci[3]
  # c(auc_value, lower, upper)
  roc_value
}

auprc_eval <- function(y_label, y_pred){
  require(pROC)
  y_pred <- as.matrix(y_pred)
  if (min(y_pred)<0){
    y_pred_label <- apply(y_pred,1,ispositive_n_p)
  }else{
    y_pred_label <- apply(y_pred,1,ispositive_0_1) 
  }
  fg = y_pred[y_label==1]
  bg = y_pred[y_label==0]
  auroc <- PRROC::roc.curve(fg,bg)
  auprc <- PRROC::pr.curve(fg,bg)
  c(auroc[2], auprc[2])
}

log <- ''

drugs <- c('Naproxen','Celecoxib','Acetaminophen','Vancomycin','Candesartan','Celecoxib_2',
           'Irbesartan','Olmesartan','Losartan','Valsartan')
for (drug in drugs){
  # drug <- 'Naproxen'
  # output.file.train <- glue('stage2/output/{drug}_{insti}_train_predict.RData')
  weight <- readRDS(glue('stage3/output/{drug}_lasso_standard_weights_3insti.rds'))
  weight_mean <- apply(weight,2,mean)
  
  output.file.val_gangnam <- glue('stage2/output/{drug}_gangnam_val_predict.RData')
  output.file.val_konyang <- glue('stage2/output/{drug}_konyang_val_predict.RData')
  output.file.val_sinchon <- glue('stage2/output/{drug}_sinchon_val_predict.RData')
  load(output.file.val_gangnam)
  load(output.file.val_konyang)
  load(output.file.val_sinchon)
  
  predict_lasso_gd_gm <- gangnam_val_predict_gangnam_lasso
  predict_lasso_gd_km <- gangnam_val_predict_konyang_lasso
  predict_lasso_gd_sm <- gangnam_val_predict_sinchon_lasso
  predict_lasso_kd_gm <- konyang_val_predict_gangnam_lasso
  predict_lasso_kd_km <- konyang_val_predict_konyang_lasso
  predict_lasso_kd_sm <- konyang_val_predict_sinchon_lasso
  predict_lasso_sd_gm <- sinchon_val_predict_gangnam_lasso
  predict_lasso_sd_km <- sinchon_val_predict_konyang_lasso
  predict_lasso_sd_sm <- sinchon_val_predict_sinchon_lasso
  
  predict_lasso_gd_wim <- predict_lasso_gd_gm*weight_mean[1] +
                            predict_lasso_gd_km*weight_mean[2] +
                              predict_lasso_gd_sm*weight_mean[3]
  predict_lasso_kd_wim <- predict_lasso_kd_gm*weight_mean[1] +
                            predict_lasso_kd_km*weight_mean[2] +
                              predict_lasso_kd_sm*weight_mean[3]
  predict_lasso_sd_wim <- predict_lasso_sd_gm*weight_mean[1] +
                            predict_lasso_sd_km*weight_mean[2] +
                              predict_lasso_sd_sm*weight_mean[3]
  
  predict_lasso_gm <- c(predict_lasso_gd_gm, predict_lasso_kd_gm, predict_lasso_sd_gm)
  predict_lasso_km <- c(predict_lasso_gd_km, predict_lasso_kd_km, predict_lasso_sd_km)
  predict_lasso_sm <- c(predict_lasso_gd_sm, predict_lasso_kd_sm, predict_lasso_sd_sm)
  predict_lasso_wim <- c(predict_lasso_gd_wim, predict_lasso_kd_wim, predict_lasso_sd_wim)
  
  
  predict_xgb_gd_gm <- gangnam_val_predict_gangnam_xgb
  predict_xgb_gd_km <- gangnam_val_predict_konyang_xgb
  predict_xgb_gd_sm <- gangnam_val_predict_sinchon_xgb
  predict_xgb_kd_gm <- konyang_val_predict_gangnam_xgb
  predict_xgb_kd_km <- konyang_val_predict_konyang_xgb
  predict_xgb_kd_sm <- konyang_val_predict_sinchon_xgb
  predict_xgb_sd_gm <- sinchon_val_predict_gangnam_xgb
  predict_xgb_sd_km <- sinchon_val_predict_konyang_xgb
  predict_xgb_sd_sm <- sinchon_val_predict_sinchon_xgb
  predict_xgb_gd_wim <- predict_xgb_gd_gm*weight_mean[1] + 
                          predict_xgb_gd_km*weight_mean[2]+
                            predict_xgb_gd_sm*weight_mean[3]
  predict_xgb_kd_wim <- predict_xgb_kd_gm*weight_mean[1] + 
                          predict_xgb_kd_km*weight_mean[2] +
                            predict_xgb_kd_sm*weight_mean[3]
  predict_xgb_sd_wim <- predict_xgb_sd_gm*weight_mean[1] + 
                          predict_xgb_sd_km*weight_mean[2] +
                            predict_xgb_sd_sm*weight_mean[3]
                      
  predict_xgb_gm <- c(predict_xgb_gd_gm, predict_xgb_kd_gm, predict_xgb_sd_gm)
  predict_xgb_km <- c(predict_xgb_gd_km, predict_xgb_kd_km, predict_xgb_sd_km)
  predict_xgb_sm <- c(predict_xgb_gd_sm, predict_xgb_kd_sm, predict_xgb_sd_sm)
  predict_xgb_wim <- c(predict_xgb_gd_wim, predict_xgb_kd_wim, predict_xgb_sd_wim)
  
  
  response_gangnam <- readRDS(glue('stage1/output/{drug}_gangnam_val_label.rds'))
  response_konyang <- readRDS(glue('stage1/output/{drug}_konyang_val_label.rds'))
  response_sinchon <- readRDS(glue('stage1/output/{drug}_sinchon_val_label.rds'))
  response <- c(response_gangnam,response_konyang,response_sinchon)
  
  outcome <- sum(response==1)
  target <- length(response)
  
  roc_val_lasso <- auc_eval(response, predict_lasso_wim)
  roc_val_lasso_val <- roc_val_lasso$auc[1]
  roc_val_lasso_lower <- roc_val_lasso$ci[1]
  roc_val_lasso_upper <- roc_val_lasso$ci[3]
  
  roc_val_xgb <- auc_eval(response, predict_xgb_wim)
  roc_val_xgb_val <- roc_val_xgb$auc[1]
  roc_val_xgb_lower <- roc_val_xgb$ci[1]
  roc_val_xgb_upper <- roc_val_xgb$ci[3]
  
  
  log <- paste0(log,'\n\n\n',drug)
  log <- paste0(log,'\n',outcome,'/',target,'  ', (outcome/target)*100)
  log<-  paste0(log,'\nAUROC, lasso : ',auprc_eval(response, predict_lasso_wim)[1])
  log<-  paste0(log,'\nAUPRC, lasso : ',auprc_eval(response, predict_lasso_wim)[2])
  log<-  paste0(log,'\nOrigin AUROC, lasso : ',roc_val_lasso_val)
  log<-  paste0(log,'\nRange AUROC, lasso : (',round(roc_val_lasso_lower,3),'-',round(roc_val_lasso_upper,3),')')
  
  
  log<-  paste0(log,'\n\nAUROC, xgb : ',auprc_eval(response, predict_xgb_wim)[1])
  log<-  paste0(log,'\nAUPRC, xgb : ',auprc_eval(response, predict_xgb_wim)[2])
  log<-  paste0(log,'\nOrigin AUROC, xgb : ',roc_val_xgb_val)
  log<-  paste0(log,'\nRange AUROC, xgb : (',round(roc_val_xgb_lower,3),'-',round(roc_val_xgb_upper,3),')')
  
  

  png(glue('result_3insti/{drug}_lasso_wim.png'))
  plot.roc(roc_val_lasso, color='red', print.thres.pch=19, print.thres.col = "red",
           auc.polygon=TRUE, auc.polygon.col="#66CCFF")
  grid()
  dev.off()

  png(glue('result_3insti/{drug}_xgb_wim.png'))
  plot.roc(roc_val_xgb, color='red', print.thres.pch=19, print.thres.col = "red",
           auc.polygon=TRUE, auc.polygon.col="#66CCFF")
  grid()
  dev.off()
}
writeLines(log, "result_3insti/log_3insti.txt")

roc_val_xgb_entire[4]
roc_val_xgb_entire[2]
roc_val_xgb_lower

log <- ''

drugs <- c('Naproxen','Celecoxib','Acetaminophen','Vancomycin','Candesartan','Celecoxib_2',
           'Irbesartan','Olmesartan','Losartan','Valsartan')
for (drug in drugs){
  log <- paste0(log,'\n\n', drug)
  gg_tr <- readRDS(glue('stage1/output/{drug}_gangnam_train_label.rds'))
  gg_val <- readRDS(glue('stage1/output/{drug}_gangnam_val_label.rds'))
  kk_tr <- readRDS(glue('stage1/output/{drug}_konyang_train_label.rds'))
  kk_val <- readRDS(glue('stage1/output/{drug}_konyang_val_label.rds'))
  ss_tr <- readRDS(glue('stage1/output/{drug}_sinchon_train_label.rds'))
  ss_val <- readRDS(glue('stage1/output/{drug}_sinchon_val_label.rds'))
  
  log <- paste0(log,'\n gangnam_train length : ',length(gg_tr))
  log <- paste0(log,'\n gangnam_train == 1 : ',sum(gg_tr==1))
  log <- paste0(log,'\n gangnam_train == 0 : ',sum(gg_tr==0))
  log <- paste0(log,'\n gangnam_val length : ',length(gg_val))
  log <- paste0(log,'\n gangnam_val == 1 : ',sum(gg_val==1))
  log <- paste0(log,'\n gangnam_val == 0 : ',sum(gg_val==0))
  
  log <- paste0(log,'\n konyang_train length : ',length(kk_tr))
  log <- paste0(log,'\n konyang_train == 1 : ',sum(kk_tr==1))
  log <- paste0(log,'\n konyang_train == 0 : ',sum(kk_tr==0))
  log <- paste0(log,'\n konyang_val length : ',length(kk_val))
  log <- paste0(log,'\n konyang_val == 1 : ',sum(kk_val==1))
  log <- paste0(log,'\n konyang_val == 0 : ',sum(kk_val==0))
  
  log <- paste0(log,'\n sinchon_train length : ',length(ss_tr))
  log <- paste0(log,'\n sinchon_train == 1 : ',sum(ss_tr==1))
  log <- paste0(log,'\n sinchon_train == 0 : ',sum(ss_tr==0))
  log <- paste0(log,'\n sinchon_val length : ',length(ss_val))
  log <- paste0(log,'\n sinchon_val == 1 : ',sum(ss_val==1))
  log <- paste0(log,'\n sinchon_val == 0 : ',sum(ss_val==0))

  
}
writeLines(log, "log2_3insti.txt")






for (drug in drugs){
  
  png(glue('result_3insti/{drug}_lasso_wim.png'))
  plot.roc(roc_val_lasso, color='red', print.thres.pch=19, print.thres.col = "red",
           auc.polygon=TRUE, auc.polygon.col="#66CCFF")
  grid()
  dev.off()
  
  png(glue('result_3insti/{drug}_xgb_wim.png'))
  plot.roc(roc_val_xgb, color='red', print.thres.pch=19, print.thres.col = "red",
           auc.polygon=TRUE, auc.polygon.col="#66CCFF")
  grid()
  dev.off()
}


