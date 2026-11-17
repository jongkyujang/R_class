# ============================================================
# 02. 데이터 프레임 다루기
# ============================================================
# 학습 목표
# - 데이터 프레임의 행과 열 이해하기
# - 데이터 구조 확인하기
# - 원하는 행과 열 선택하기
# - 조건에 따라 필터링하고 요약하기
# - CSV 파일로 저장하고 불러오기
#
# 실행: Cmd + Enter (Mac) / Ctrl + Enter (Windows)


# ============================================================
# 1. 데이터 프레임 불러오기
# ============================================================
# 데이터 프레임은 행과 열로 구성된 표입니다.
# 이 예제에서는 한 행이 환자 한 명, 한 열이 변수 하나입니다.
# 열마다 자료형은 다를 수 있지만 값의 개수는 같아야 합니다.

patients <- read.csv("R_class/doc/patients.csv")
patients

# 오른쪽 enviroment 창에서 "patients" 데이터를 눌러 표 형태로도 확인 가능 (혹은 아래 콘솔창에 "View(patients)" 입력)
# ============================================================
# 2. 데이터 구조 확인하기
# ============================================================

head(patients)          # 앞부분 확인
head(patients, n = 3)   # 처음 3개 행
tail(patients, n = 3)   # 마지막 3개 행

dim(patients)          # 행 수, 열 수
nrow(patients)         # 행 수
ncol(patients)         # 열 수
colnames(patients)     # 열 이름

str(patients)         # 각 열의 자료형과 값
summary(patients)     # 열별 요약

# RStudio에서 표 형태로 열기
View(patients)


# ============================================================
# 3. 열 선택하기
# ============================================================

# $ 뒤에 열 이름을 넣으면 해당 열을 벡터로 가져옵니다.
patients$age
patients$expression

mean(patients$age)

# 대괄호 안에 열 이름을 넣으면 데이터 프레임으로 가져옵니다.
patients["age"]

# 여러 열 선택
patients[c("patient_id", "expression")]

# 같은 값이라도 가져오는 형태가 다를 수 있습니다.
class(patients$age)
class(patients["age"])


# ============================================================
# 4. 행과 열 선택하기
# ============================================================
# 데이터프레임[행, 열]
# 쉼표 앞은 행, 쉼표 뒤는 열입니다.
# 한쪽을 비우면 해당 방향 전체를 선택합니다.

patients[1, ]       # 첫 번째 행
patients[, 2]      # 두 번째 열
patients[1, 2]     # 첫 번째 행, 두 번째 열

patients[1:3, ]    # 처음 3개 행
patients[, c("patient_id", "age")]

patients[1:3, c("patient_id", "expression")]


# ============================================================
# 5. 조건에 맞는 행 선택하기
# ============================================================

# 먼저 각 환자가 조건에 해당하는지 확인합니다.
patients$age >= 50

# TRUE인 행만 선택합니다.
patients[patients$age >= 50, ]

# Treatment 그룹만 선택
patients[patients$group == "Treatment", ]

# 40세 이상이면서 발현값이 200 이상
patients[
  (patients$age >= 40) & (patients$expression >= 200),
]

# 조건에 맞는 환자의 ID만 선택
patients$patient_id[patients$expression >= 200]


# ============================================================
# 6. 새 열 추가하기
# ============================================================

patients$age_group <- ifelse(
  patients$age >= 50,
  "50세 이상",
  "50세 미만"
)

patients

# 발현값에 1을 더하고 log2 변환
# 여기서는 열을 만드는 방법을 연습합니다.
patients$log2_expression <- log2(patients$expression + 1)

patients


# ============================================================
# 7. 정렬하기
# ============================================================
# order()는 정렬에 필요한 행의 순서를 반환합니다.

order(patients$age)

# 나이 오름차순
patients[order(patients$age), ]

# 발현값 내림차순
patients[order(patients$expression, decreasing = TRUE), ]

# 정렬 결과를 저장해야 원래 객체가 바뀝니다.
patients_sorted <- patients[
  order(patients$expression, decreasing = TRUE),
]

patients_sorted


# ============================================================
# 8. dplyr로 데이터 다루기
# ============================================================

library(dplyr)

# |>는 왼쪽 결과를 오른쪽 함수의 첫 번째 인자로 전달합니다.
# 아래 두 코드는 같은 작업입니다.

select(patients, patient_id, age)

patients |>
  select(patient_id, age)


# ------------------------------------------------------------
# select(): 열 선택
# ------------------------------------------------------------

patients |>
  select(patient_id, group, expression)


# ------------------------------------------------------------
# filter(): 조건에 맞는 행 선택
# ------------------------------------------------------------

patients |>
  filter(age >= 50)

# 여러 조건을 쉼표로 연결하면 모두 만족하는 행을 선택합니다.
patients |>
  filter(age >= 40, expression >= 200)


# ------------------------------------------------------------
# mutate(): 열 추가 또는 수정
# ------------------------------------------------------------

patients |>
  mutate(
    expression_group = ifelse(expression >= 200, "High", "Low")
  )

# 위 코드는 결과를 출력할 뿐 patients를 바꾸지는 않습니다.
# 결과를 저장하려면 <-를 사용합니다.
patients <- patients |>
  mutate(
    expression_group = ifelse(expression >= 200, "High", "Low")
  )


# ------------------------------------------------------------
# arrange(): 행 정렬
# ------------------------------------------------------------

patients |>
  arrange(age)

patients |>
  arrange(desc(expression))


# ------------------------------------------------------------
# 여러 작업 연결하기
# ------------------------------------------------------------

patients |>
  filter(age >= 40) |>
  select(patient_id, age, expression) |>
  arrange(desc(expression))


# ============================================================
# 9. 전체·그룹별 요약 통계
# ============================================================

patients |>
  summarise(
    n_patients = n(),
    mean_age = mean(age),
    mean_expression = mean(expression),
    median_expression = median(expression)
  )

# group_by(): 이후 계산을 그룹별로 수행하도록 지정
patients |>
  group_by(group) |>
  summarise(
    n_patients = n(),
    mean_expression = mean(expression),
    sd_expression = sd(expression),
    .groups = "drop"
  )

# 그룹별 환자 수
patients |>
  count(group)


# ============================================================
# 10. 결측값이 있는 데이터
# ============================================================

# 원본과 별도로 연습용 객체를 만듭니다.
patients_missing <- patients
patients_missing$expression[c(2, 5)] <- NA

patients_missing

# 열별 결측값 개수
colSums(is.na(patients_missing))

# 발현값이 결측인 환자
patients_missing |>
  filter(is.na(expression))

# 발현값이 관측된 환자
patients_missing |>
  filter(!is.na(expression))

# 결측값을 제외한 그룹별 평균
patients_missing |>
  group_by(group) |>
  summarise(
    n_observed = sum(!is.na(expression)),
    mean_expression = mean(expression, na.rm = TRUE),
    .groups = "drop"
  )


# ============================================================
# 11. CSV 저장과 불러오기
# ============================================================
# 상대 경로는 현재 작업 폴더를 기준으로 해석됩니다.

getwd()

# 현재 작업 폴더 아래에 outputs 폴더를 만듭니다.
dir.create("outputs", showWarnings = FALSE)

# row.names = FALSE: 별도의 행 번호를 파일에 저장하지 않습니다.
write.csv(
  patients,
  file = "outputs/patients_practice.csv",
  row.names = FALSE
)

# 저장한 CSV를 다시 읽습니다.
patients_loaded <- read.csv(
  "outputs/patients_practice.csv"
)

head(patients_loaded)
str(patients_loaded)

