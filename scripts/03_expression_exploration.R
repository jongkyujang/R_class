# ============================================================
# 03. 가상 환자 RNA 발현 데이터 탐색과 시각화
# ============================================================
# 학습 목표
# - 유전자 × 환자 형태의 발현 행렬 이해하기
# - 환자별 총 count와 유전자별 기술통계 확인하기
# - 히스토그램, 박스플롯, 산점도 그리기
#
# 아래 데이터는 수업용으로 생성한 가상 count 데이터입니다.
# 실제 환자 데이터가 아니며, 단순화된 시뮬레이션입니다.

library(tidyverse)


# ============================================================
# 1. 가상 환자 정보 만들기
# ============================================================
# set.seed(): 같은 난수를 생성해 결과를 재현합니다.

set.seed(123)

metadata <- data.frame(
  patient_id = sprintf("P%02d", 1:24),
  group = rep(c("Control", "Treatment"), each = 12),
  age = sample(30:75, size = 24, replace = TRUE)
)

head(metadata)
table(metadata$group)


# ============================================================
# 2. 가상 RNA count 행렬 만들기
# ============================================================
# 행: 유전자 100개
# 열: 환자 24명
# 값: 각 환자에서 관측된 유전자별 count
#
# 환자마다 총 count가 달라지고, 일부 유전자는 그룹 간
# 평균 발현이 다르도록 설정합니다.
# 여기서 부여한 차이는 실제 치료 효과를 의미하지 않습니다.

n_genes <- 100
n_patients <- nrow(metadata)

gene_ids <- sprintf("GENE_%03d", 1:n_genes)

# 유전자별 기본 발현 수준
baseline <- rlnorm(
  n_genes,
  meanlog = 4,
  sdlog = 1
)

# 환자별 count 규모 차이를 만드는 가상 계수
sample_factor <- exp(
  seq(log(0.5), log(2), length.out = n_patients)
)

sample_factor <- sample(sample_factor)

# 각 유전자·환자 조합의 평균 count
expected_counts <- outer(baseline, sample_factor)

# Treatment 그룹에서 처음 10개 유전자의 평균을 3배로 설정
treatment_columns <- metadata$group == "Treatment"

expected_counts[1:10, treatment_columns] <-
  expected_counts[1:10, treatment_columns] * 3

# 음이항분포에서 가상 count 생성
counts <- matrix(
  rnbinom(
    n_genes * n_patients,
    mu = as.vector(expected_counts),
    size = 10
  ),
  nrow = n_genes,
  ncol = n_patients,
  dimnames = list(gene_ids, metadata$patient_id)
)

# 처음 6개 유전자와 5명의 환자
counts[1:6, 1:5]

dim(counts)
class(counts)

# 데이터 프레임과 달리 행렬은 모든 값의 자료형이 같습니다.


# ============================================================
# 3. 데이터 저장하기
# ============================================================
# 다음 실습에서도 이 파일들을 사용합니다.
# 저장 위치는 현재 작업 폴더 기준입니다.

getwd()

dir.create("data", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

write.csv(
  metadata,
  "data/patient_metadata.csv",
  row.names = FALSE
)

# 유전자 ID를 명시적인 열로 저장
counts_table <- data.frame(
  gene_id = rownames(counts),
  counts,
  row.names = NULL
)

write.csv(
  counts_table,
  "data/expression_counts.csv",
  row.names = FALSE
)


# ============================================================
# 4. 환자별 총 count 확인하기
# ============================================================
# colSums(): 열별 합계
# 이 데이터에서는 측정한 100개 유전자의 총 count입니다.

total_counts <- colSums(counts)

total_counts

patient_summary <- metadata |>
  mutate(
    total_count = total_counts[patient_id],
    detected_genes = colSums(counts > 0)[patient_id]
  )

patient_summary

summary(patient_summary$total_count)

# 가장 총 count가 많은 환자부터 정렬
patient_summary |>
  arrange(desc(total_count))


# ============================================================
# 5. 환자별 총 count 시각화
# ============================================================

p_total <- ggplot(
  patient_summary,
  aes(x = patient_id, y = total_count, fill = group)
) +
  geom_col() +
  labs(
    title = "Total counts per patient",
    x = "Patient",
    y = "Total count",
    fill = "Group"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_total)


# ============================================================
# 6. 유전자별 기술통계
# ============================================================
# rowMeans(): 행별 평균
# apply(counts, 1, 함수): 각 행에 함수 적용
# apply(counts, 2, 함수): 각 열에 함수 적용

gene_summary <- data.frame(
  gene_id = rownames(counts),
  mean_count = rowMeans(counts),
  median_count = apply(counts, 1, median),
  sd_count = apply(counts, 1, sd),
  detected_patients = rowSums(counts > 0)
)

head(gene_summary)

# 평균 count가 높은 유전자 10개
gene_summary |>
  arrange(desc(mean_count)) |>
  head(10)


# ============================================================
# 7. 시각화를 위한 긴 형태의 데이터 만들기
# ============================================================
# 기존: 한 행에 유전자 하나, 여러 환자 열
# 변환 후: 한 행에 유전자·환자 조합 하나
#
# 유전자 100개 × 환자 24명 = 2,400개 행

expression_long <- counts_table |>
  pivot_longer(
    cols = -gene_id,
    names_to = "patient_id",
    values_to = "count"
  ) |>
  left_join(metadata, by = "patient_id")

head(expression_long)
nrow(expression_long)

# left_join(): patient_id가 같은 환자 정보를 붙입니다.


# ============================================================
# 8. 발현값 분포: 히스토그램
# ============================================================
# x축: count
# y축: 해당 구간에 들어가는 유전자·환자 조합의 개수

p_histogram <- ggplot(
  expression_long,
  aes(x = count)
) +
  geom_histogram(
    bins = 40,
    fill = "steelblue",
    color = "white"
  ) +
  labs(
    title = "Distribution of raw counts",
    x = "Raw count",
    y = "Frequency"
  ) +
  theme_bw()

print(p_histogram)

# 질문:
# 작은 값과 큰 값 중 어느 쪽에 관측값이 많이 모여 있나요?
# 매우 큰 값 때문에 작은 값의 분포를 보기 어렵지 않나요?


# ============================================================
# 9. 로그 변환 후 분포 확인하기
# ============================================================
# log2(count + 1)
# 0에도 적용할 수 있도록 1을 더합니다.
# 큰 값의 범위를 압축해 분포를 살펴보기 위한 변환입니다.
# 환자별 총 count 차이를 보정하는 정규화는 아닙니다.

expression_long <- expression_long |>
  mutate(log2_count = log2(count + 1))

p_log_histogram <- ggplot(
  expression_long,
  aes(x = log2_count)
) +
  geom_histogram(
    bins = 40,
    fill = "darkorange",
    color = "white"
  ) +
  labs(
    title = "Distribution after log transformation",
    x = "log2(count + 1)",
    y = "Frequency"
  ) +
  theme_bw()

print(p_log_histogram)


# ============================================================
# 10. 환자별 분포: 박스플롯
# ============================================================
# 환자 한 명의 상자에는 유전자 100개의 값이 반영됩니다.
# 상자: 1사분위수 ~ 3사분위수
# 상자 안의 선: 중앙값
# 수염 밖 점: 기본 규칙상 잠재적 이상값이며,
#             자동으로 제거해야 하는 값은 아닙니다.

p_boxplot <- ggplot(
  expression_long,
  aes(x = patient_id, y = log2_count, fill = group)
) +
  geom_boxplot() +
  labs(
    title = "Expression distribution per patient",
    x = "Patient",
    y = "log2(count + 1)",
    fill = "Group"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_boxplot)


# ============================================================
# 11. 특정 유전자 비교하기
# ============================================================

selected_gene <- "GENE_001"

selected_data <- expression_long |>
  filter(gene_id == selected_gene)

selected_data

# 그룹별 기술통계
selected_data |>
  group_by(group) |>
  summarise(
    n_patients = n(),
    mean_count = mean(count),
    median_count = median(count),
    sd_count = sd(count),
    .groups = "drop"
  )

# 점 하나는 환자 한 명을 나타냅니다.
p_gene <- ggplot(
  selected_data,
  aes(x = group, y = count, color = group)
) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.1, height = 0) +
  labs(
    title = selected_gene,
    x = "Group",
    y = "Raw count"
  ) +
  theme_bw() +
  theme(legend.position = "none")

print(p_gene)

# 아직 환자별 총 count를 보정하지 않은 값입니다.
# 이 그림만으로 그룹 간 생물학적 차이를 판단하지 않습니다.


# ============================================================
# 12. 두 환자의 발현값 비교하기
# ============================================================
# 점 하나는 유전자 하나를 나타냅니다.

patient_comparison <- data.frame(
  gene_id = rownames(counts),
  P01 = counts[, "P01"],
  P02 = counts[, "P02"]
)

p_scatter <- ggplot(
  patient_comparison,
  aes(x = log2(P01 + 1), y = log2(P02 + 1))
) +
  geom_point(alpha = 0.6) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    color = "red"
  ) +
  coord_equal() +
  labs(
    title = "Comparison of two patients",
    x = "P01: log2(count + 1)",
    y = "P02: log2(count + 1)"
  ) +
  theme_bw()

print(p_scatter)

# 빨간 점선은 두 환자의 값이 같은 위치입니다.


# ============================================================
# 13. 결과 저장하기
# ============================================================

write.csv(
  patient_summary,
  "outputs/patient_summary.csv",
  row.names = FALSE
)

write.csv(
  gene_summary,
  "outputs/gene_summary.csv",
  row.names = FALSE
)

ggsave(
  "outputs/patient_total_counts.png",
  plot = p_total,
  width = 9,
  height = 5,
  dpi = 150
)

ggsave(
  "outputs/patient_expression_boxplot.png",
  plot = p_boxplot,
  width = 9,
  height = 5,
  dpi = 150
)


# ============================================================
# 14. 실습 문제
# ============================================================

# 문제 1. 총 count가 가장 적은 환자를 찾으세요.


# 문제 2. 평균 count가 가장 높은 유전자 5개를 확인하세요.


# 문제 3. selected_gene을 "GENE_050"으로 바꾸고,
#         11번 부분을 다시 실행해 그림을 비교하세요.


# 문제 4. 히스토그램의 bins를 10과 80으로 바꿔보세요.
#         분포가 어떻게 다르게 보이나요?


# 문제 5. P01과 P02 대신 P03과 P04를 비교하는
#         산점도를 그려보세요.


# 문제 6. 환자별 박스플롯에서 중앙값이 높은 환자가
#         총 count도 높은지 확인하세요.
