# R 기초 실습

웹브라우저에서 RStudio를 실행해 R 기초와 가상 환자 RNA 발현 데이터 분석을 실습합니다.

## 1. 실습 환경 시작하기

별도로 R이나 RStudio를 설치할 필요가 없습니다. GitHub 계정이 필요합니다.

1. 아래 링크를 클릭합니다.
2. 본인 GitHub 계정으로 로그인합니다.
3. 환경 생성 화면에서 `Create codespace`를 클릭합니다.
4. 환경 준비가 끝날 때까지 기다립니다. 최초 생성에는 몇 분이 걸릴 수 있습니다.

[실습 환경 만들기](https://codespaces.new/jongkyujang/R_class)

학생마다 독립적인 실습 환경이 생성됩니다.

## 2. RStudio 접속하기
1. Codespaces 화면 아래의 **PORTS** 탭을 엽니다.
2. **8787 / RStudio** 행을 찾습니다.
3. **Forwarded Address** 열에 위치한 주소(http://로 시작)를 복사하여 새로운 탭이나 창에 복사하여 실행

혹은 ctrl(Mac은 Cmd)+Shift+P 후 위의 창에서 Open port in Browser -> 8787 port 선택하면 바로 창이 열립니다. 

RStudio 자체의 아이디와 비밀번호는 입력하지 않습니다.
GitHub 접속 인증이 표시되면 Codespace를 생성한 계정으로 진행합니다.

> PORTS 탭에서 제공하는 주소로 접속해야 합니다.
> 8787 포트의 공개 범위는 **Private**으로 유지하세요.

## 3. 수업 내용

1. R 기본 문법
   - 변수와 자료형
   - 벡터와 기본 함수
   - 비교·논리 연산
   - 조건문과 반복문

2. 데이터 프레임
   - 데이터 구조 확인
   - 행과 열 선택
   - 조건에 따른 필터링
   - 요약 통계 계산

3. 가상 환자 RNA 발현 데이터 탐색
   - 데이터 불러오기
   - 발현값의 분포와 기술통계 확인
   - 히스토그램, 박스플롯 등으로 시각화

4. 정규화와 클러스터링
   - 정규화와 로그 변환의 개념
   - 유전자별 스케일링
   - Heatmap 시각화
   - 계층적 클러스터링

실습에는 학습용 가상 데이터를 사용합니다.

## 4. 설치된 환경

- R 및 RStudio Server
- tidyverse: ggplot2, dplyr, tidyr, readr 등
- pheatmap

필요한 패키지는 미리 설치되어 있습니다.
RStudio Console에서 아래 명령으로 불러올 수 있습니다.

```r
library(tidyverse)
library(pheatmap)
```

## 5. 실습 종료하기

1. 작성한 R 스크립트를 저장합니다.
2. 필요한 결과 파일은 다운로드합니다.
3. https://github.com/codespaces 에 접속합니다.
4. 사용 중인 Codespace의 **… → Stop codespace**를 클릭합니다.

브라우저 탭만 닫으면 환경이 즉시 종료되지 않을 수 있습니다.
다음 실습에서는 기존 Codespace를 다시 실행하면 됩니다.

> Codespace를 삭제하면 커밋·푸시하거나 다운로드하지 않은 작업은 사라집니다.
