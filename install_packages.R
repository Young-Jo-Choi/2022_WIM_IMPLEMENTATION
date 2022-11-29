install.packages("repr", repos = "http://cran.us.r-project.org")
install.packages("dplyr", repos = "http://cran.us.r-project.org")
install.packages("glmnet", repos = "http://cran.us.r-project.org")
install.packages("glue", repos = "http://cran.us.r-project.org")
install.packages("here", repos = "http://cran.us.r-project.org")
packageurl_xgboost <- "http://cran.r-project.org/src/contrib/Archive/xgboost/xgboost_0.90.0.2.tar.gz"
install.packages(packageurl_xgboost, repos=NULL, type="source")

# 인터넷이 안되는 환경에서 패키지를 설치해야한다면 
# 바깥 환경에서 다음과 같은 명령어로 패키지 설치 파일과 dependency 패키지 설치 파일을 다운로드 받을 수 있다.

# getPackages<-function(packs){
#   packages<-unlist(
#     #Find(recursively)dependenciesorreversedependenciesofpackages.
#     tools::package_dependencies(packs,available.packages(),
#                                 which=c("Depends","Imports"),recursive=TRUE)
#   )
#   packages<-union(packs,packages)
#   return(packages)
# }

# glue 패키지를 예시로 사용
# packages <- getPackages(c('glue'))
# download.packages(pkgs = packages, destdir = 'package_glue/', type ='source')
