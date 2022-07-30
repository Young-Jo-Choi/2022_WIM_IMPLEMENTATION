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
- settings.R :
    - 폴더에 기관의 이름(NCC or SEV)을 기재하거나 설정을 바꿀 수 있는 script
    - 설정을 바꿀 일이 있다면 settings.R에 들어가 수정해야함, 단 단독으로 실행하지 않음
- utils.R :
    - 자주 사용되는 loading, namer function 등이 정의되어 있음.
- table_generating.ipynb
    - 원본 파일로부터 데이터를 가공해 input 데이터를 만들어주는 python code


## program 실행방법
### Preparation ( 준비 ) 
- 먼저 install_packages.R을 실행.
- settings.R
    - settings.R을 확인하여 기관이 이름이 NCC or SEV 인지 확인(이미 NCC로 설정해놓음)
    
- 각 stage를 순차적으로 실행하되 다른 기관(SEV)과 순서에 맞춰 진행돼야 함. 또한, input 폴더에 필요한 파일들이 있는지 꼭 확인해줘야 합니다.(아래에 기재함)
- 보내주셔야 하는 메일 주소 : a6672284@gmail.com
> 용어
> * global : 서버환경 - 현재는 SEV를 서버로 가정
> * local : 각 기관 자체 - SEV, NCC



### STAGE 1
- 데이터 분할 및 lasso logistic 모형 생성단계
    - 환경 : local 환경
    - n_F 수정 : SEV와 확인하여 공통된 변수 개수를 정해줌 --> settings.R에서 수정
    - stage 1 directory의 stage_1.R실행
    * ***기관의 이름은 settings에 따라 H1, H2로 지정되게 되어 있습니다. H1은 SEV이며, H2는 NCC입니다.(참고: settings.R)***
    - 실행 : 
    ```
    Rscript stage1/stage_1_lasso.R
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) 없음

    - input : 
        1) {기관}.csv 

    - output :
        1) 기관_changed_data.rds
        2) Z1Z2_기관.rds
        3) total_model_기관.rds
        4) lambda_기관.rds
        5) 기관_fit.rds

    - 다른 기관으로 보내야 할 output : 
        1) total_model_기관.rds
        2) lambda_기관.rds
        3) 기관_fit.rds
        - a6672284@gmail.com로 보내주시면 됩니다.

### STAGE 2
- loss 구하는 단계
    - 환경 : local 환경
    - stage 2 디렉토리의 stage_2.R 실행
    - 실행 : 
    ```
    Rscript stage2/stage_2_lasso.R
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) 모든 기관의 total_models (total_model_기관.rds)

    - input : 
        1) 모든 기관의 total_models (total_model_기관.rds)
        2) Z1Z2_기관.rds
    
    - output : 
        1) loss Matrix_기관
    
    - 다른 기관으로 보내야 할 output :
        1) lossMatrix_{기관}.rds
        - 기관의 loss Matrix를 server로 보내줘야 함. 
        - a6672284@gmail.com로 보내주시면 됩니다.

### STAGE 3
- loss 취합 및 WIM weight 구하는 단계
    - 환경 : Server(현재는 SEV가 server 역할)
    - **stage 3는 중앙서버에서 진행되므로 각 클라이언트에서는 수행하지 않아도 됨
    - stage 3 디렉토리의 stage_3.R 실행
    - 실행 : 
    ```
    Rscript stgae3/stage_3_lasso.R
    ```
    - 다른 기관에서 받아야 하는 데이터
        1) lossMatrix_H1.rds

    - input : 
        1) loss Matrix(모든기관)
        2) total_models(모든 기관)
    - output : 
        1) WIM_standard_beta : (n_I x n_F)
        2) WIM_standard_weights : (n_I x n_H)
    - 다른 기관에 보내댜 할 output : 
        1) WIM_standard_beta.rds
        - 기관의 WIM_standard_beta를 각 기관이 모두 공유해야 함
