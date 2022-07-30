## functions

namer_function <- function(local_data) {
    df <- local_data
    df_Y <- df %>% select(Y = {{ y }})
    df_X <- df %>% select(-c({{ y }}))

    # rename X's
    colnames(df_X) <- 1:dim(df_X)[2] %>% purrr::map_chr(~ glue("x{.}"))
    changed_data <- bind_cols(df_Y, df_X)

    return(changed_data)
}


load_files <- function(pattern, path, as_list = FALSE) {

    # as list true일 경우 2개 이상의 데이터를 한번에 리스트로 불러온다.
    fileLists <- list.files(path)
    files <- fileLists[grep(pattern, fileLists)]
    print(glue("files are {files}"))
    full_path <- files %>% map_chr(~ here(path, .))
    mapply(function(x, y) assign(str_sub(y, length(y), -5), readRDS(x), envir = globalenv()), full_path, files)

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
