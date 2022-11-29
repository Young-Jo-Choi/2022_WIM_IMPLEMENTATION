# 2022_LASSO_WIM
- WIM는 다기관 연구를 위해서 고안된 방법론임
- 사용모델 : 
- 알고리즘 저자 : JI AE PARK
- 코드 구현 : WONSEOK JANG, YOUNGJO CHOI

## program 구성
- stage1 ~ stage3까지로 되어 있음
- 각 기관끼리 동일한 stage를 순서에 맞춰 진행함
- 각 stage 폴더에는 stage_*.R 폴더가 존재하며 input, output 폴더가 존재함
- install_packages.R :
    - 필요한 패키지를 미리 설치해주는 script
    - 만일 인터넷이 안되는 내부 서버 사용 중이라면 주석 부분을 외부망에서 실행해 dependency packages zip file들을 다운받을 수 있습니다.
- settings.R :
    - 기본 변수 세팅에 대한 파일
    - 설정을 바꿀 일이 있다면 settings.R에 들어가 수정해야함, 단 단독으로 실행하지 않음
- utils.R :
    - 자주 사용되는 loading, namer function 등이 정의되어 있음.
- table_generating.ipynb
    - 원본 파일로부터 데이터를 가공해 input 데이터를 만들어주는 python code


## program 실행방법
### Preparation ( 준비 ) 
- 먼저 install_packages.R을 실행.

    
- 각 stage를 순차적으로 실행하되 다른 기관과 순서에 맞춰 진행돼야 함. 또한, input 폴더에 필요한 파일들이 있는지 꼭 확인해줘야 합니다.(아래에 기재함)
- 보내주셔야 하는 메일 주소 : a6672284@gmail.com
> 용어
> * global : 서버환경 - 각 기관 결과물을 취합하는 중앙 기관
> * local : 각 기관 자체 - 신촌(sinchon), 강남(gangnam), 건양대(konyang)


### STAGE 1
- 데이터 분할 및 lasso logistic, xgboost 모형 생성단계
    - 환경 : local 환경
    - stage 1 directory의 stage_1.R실행
    - 시간이 오래 걸릴 수 있음

    - 실행 : 
    ```
    Rscript stage1/stage_1.R '기관' '약물'
    ex) Rscript stage1/stage_1.R 'konyang' 'Acetaminophen'
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) 없음

    - input : 
        1) {약물}_{기관}_ExtraTrees_train.csv, {약물}_{기관}_ExtraTrees_val.csv 

    - output :
        1) {약물}_{기관}_ExtraTrees_train_changed.rds, {약물}_{기관}_ExtraTrees_val_changed.rds
            : csv file을 모델에 넣을 수 있는 형태로 약간 변형
        2) {약물}_{기관}_train_label.rds, {약물}_{기관}_val_label.rds
            : 모델 평가를 위해 취합하는 label 데이터
        3) lasso_Z1Z2_{약물}_{기관}_ExtraTrees_train.rds
            : wim loss 계산을 위해 분할된 데이터세트
        4) lasso_loss_model_{약물}_{기관}_ExtraTrees_train.rds
            : wim_loss 계산을 위해 만들어진 lasso logistic model의 계수들을 모아놓은 행렬
        5) models_{약물}_{기관}_ExtraTrees_train_fit.rds
            : train 데이터를 이용해 만들어진 기관의 모델(lasso logistic과 xgboost)



    - 다른 기관으로 보내야 할 output : 
        1) lasso_loss_model_{약물}_{기관}_ExtraTrees_train.rds
        2) models_{약물}_{기관}_ExtraTrees_train_fit.rds
        3) {약물}_{기관}_train_label.rds, {약물}_{기관}_val_label.rds
        - a6672284@gmail.com로 보내주시면 됩니다.

### STAGE 2
- loss를 구하는 단계
    - 환경 : local 환경
    - stage 2 디렉토리의 stage_2.R 실행
    - 실행 : 
    ```
    Rscript stage2/stage_2.R '기관' '약물'
    ex) Rscript stage2/stage_2.R 'konyang' 'Acetaminophen'
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) 모든 기관의 loss_models (lasso_total_model_{약물}_{기관}_ExtraTrees_train.rds)
        2) 모든 기관의 models (models_{약물}_{기관}_ExtraTrees_train_fit.rds)

    - input : 
        1) 모든 기관의 loss_models (lasso_total_model_{약물}_{기관}_ExtraTrees_train.rds)
        2) 모든 기관의 models (models_{약물}_{기관}_ExtraTrees_train_fit.rds)
        3) lasso_Z1Z2_{약물}_{기관}_ExtraTrees_train.rds
    
    - output : 
        1) lasso_lossMatrix_{약물}_{기관}_ExtraTrees_train.rds
            : 모든 기관의 loss model로 얻은 해당 기관의 loss 행렬
        2) {약물}_{기관}_train_predict.RData, {약물}_{기관}_val_predict.RData
            : 모든 기관의 lasso logistic 모델, xgboost 모델로 prediction한 결과가 들어있음
                -> ex) 변수명 : konyang_val_predict_sinchon_xgb : 신촌 데이터로 만든 xgb모델로 건양대 validation set에 대한 예측을 수행한 결과
    
    - 다른 기관으로 보내야 할 output :
        1) lasso_lossMatrix_{약물}_{기관}_ExtraTrees_train.rds
        2) {약물}_{기관}_train_predict.RData, {약물}_{기관}_val_predict.RData
        - a6672284@gmail.com로 보내주시면 됩니다.

### STAGE 3
- loss 취합 및 WIM weight 구하는 단계
    - 환경 : Server
    - **stage 3는 중앙서버에서 진행되므로 각 클라이언트에서는 수행하지 않아도 됨
    - stage 3 디렉토리의 stage_3.R 실행
    - 실행 : 
    ```
    Rscript stage3/stage_3.R '약물' 
    ex) Rscript stage3/stage_3.R 'Acetaminophen'
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) lasso_lossMatrix_{약물}_{기관}_ExtraTrees_train.rds
        2) {약물}_{기관}_train_predict.RData, {약물}_{기관}_val_predict.RData

    - input : 
        1) 모든 기관의 lasso_lossMatrix_{약물}_{기관}_ExtraTrees_train.rds
        2) 모든 기관의 {약물}_{기관}_train_predict.RData, {약물}_{기관}_val_predict.RData
        3) 모든 기관의 {약물}_{기관}_train_label.rds, {약물}_{기관}_val_label.rds
        
    - output : 
        1) WIM_standard_weights : (n_I x n_H)
        2) 각 약물과 기관별 acc와 auc


