## functions
namer_function <- function(local_data) {
    require(dplyr)
    df <- local_data
    df_Y <- df %>% select(Y = {{ y }})
    df_X <- df %>% select(-c({{ y }}))

    # rename X's
    colnames(df_X) <- 1:dim(df_X)[2] %>% purrr::map_chr(~ glue("x{.}"))
    changed_data <- bind_cols(df_Y, df_X)

    return(changed_data)
}


load_files <- function(pattern, path, as_list = FALSE) {
    require(dplyr)

    # as list true일 경우 2개 이상의 데이터를 한번에 리스트로 불러온다.
    fileLists <- list.files(path)
    files <- fileLists[grep(pattern, fileLists)]
    print(glue("files are {files}"))
    full_path <- files %>% purrr::map_chr(~ here(path, .))
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

ispositive_0_1 <- function(x){
    if (x<=0.5){
        y <-0
    }else{
        y<-1
    }
    y
}
ispositive_n_p <- function(x){
    if (x<=0){
        y <-0
    }else{
        y<-1
    }
    y
}

acc_auc <- function(y_label, y_pred){
    require(pROC)
    y_pred <- as.matrix(y_pred)
    if (min(y_pred)<0){
        y_pred_label <- apply(y_pred,1,ispositive_n_p)
    }else{
        y_pred_label <- apply(y_pred,1,ispositive_0_1) 
    }
    acc_value <- mean(y_pred_label==y_label)
    roc_value <- roc(y_label~y_pred,ci=T,quiet=T)
    auc_value <- roc_value$auc[1]
    lower <- roc_value$ci[1]
    upper <- roc_value$ci[3]
    c(acc_value, auc_value)
}


logistic_lasso_train <- function(data,label) {
    require(glmnet)
    x<-as.matrix(data[,!(names(data) %in% c(label))])
    y<-data[,label]
    local_fit_cv <- cv.glmnet(x = x,
                              y = y, family = 'binomial',alpha=1)
    local_fit <- glmnet(x = x,
                        y = y,
                        alpha=1, family="binomial",lambda=local_fit_cv$lambda.min )
    local_fit
}

xgboost_train <- function(data,label) {
    require(xgboost)
    x<-as.matrix(data[,!(names(data) %in% c(label))])
    y<-data[,label]
    xgboost_data <- xgb.DMatrix(data=x, label=y)
    # all parameters have default options
    xgb <- xgboost(data = xgboost_data,
                   objective = 'binary:logistic',
                   verbose = 0,
                   nround = 15)
    xgb
}

