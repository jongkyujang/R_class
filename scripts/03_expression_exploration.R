# ============================================================
# 03. RNA 발현 데이터 탐색과 시각화
# ============================================================
# 학습 목표
# - 유전자 × 샘플 형태의 발현 행렬 이해하기
# - 샘플별 총 count와 유전자별 기술통계 확인하기
# - 히스토그램, 박스플롯, 산점도 그리기
#
# 실제 airway RNA-seq 데이터에서 raw count 기준
# MAD가 높은 유전자 5,000개를 선택한 데이터입니다.
# 유전자 이름은 gene1~gene5000, 샘플 이름은 P1~P8입니다.
# P1~P8은 환자 ID가 아니라 실험 샘플 ID입니다.

library(tidyverse)


# ============================================================
# 1. RNA count 데이터 불러오기
# ============================================================
# 첫 번째 열의 유전자 이름을 행 이름으로 사용합니다.
# 행: 유전자 / 열: 샘플 / 값: 유전자별 read count

getwd()

counts <- read.csv(
  "R_class/doc/rna_counts.csv",
  row.names = 1
)

# 데이터 프레임을 숫자 행렬로 변환
counts <- as.matrix(counts)

# 처음 6개 유전자와 5개 샘플
counts[1:6, 1:5]

dim(counts)
class(counts)

# 행렬은 모든 값의 자료형이 같습니다.

rownames(counts)[1:6]
colnames(counts)


# ============================================================
# 2. 데이터 구조 확인하기
# ============================================================

n_genes <- nrow(counts)
n_samples <- ncol(counts)

n_genes
n_samples

# 결측값 개수
sum(is.na(counts))

# 전체 count의 최솟값과 최댓값
range(counts)

# 결과 저장 폴더
dir.create("outputs", showWarnings = FALSE)


# ============================================================
# 3. 샘플별 총 count 확인하기
# ============================================================
# colSums(): 열별 합계
# 이 데이터에서는 선택한 5,000개 유전자의 총 count입니다.
# 전체 유전자의 총 count와는 다릅니다.

total_counts <- colSums(counts)

total_counts

sample_summary <- data.frame(
  sample_id = colnames(counts),
  total_count = as.numeric(total_counts),
  detected_genes = as.numeric(colSums(counts > 0))
)

sample_summary

summary(sample_summary$total_count)

# 총 count가 많은 샘플부터 정렬
sample_summary |>
  arrange(desc(total_count))


# ============================================================
# 4. 샘플별 총 count 시각화
# ============================================================

p_total <- ggplot(
  sample_summary,
  aes(x = sample_id, y = total_count)
) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Total counts per sample",
    x = "Sample",
    y = "Total count (selected 5,000 genes)"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_total)


# ============================================================
# 5. 유전자별 기술통계
# ============================================================
# rowMeans(): 행별 평균
# apply(counts, 1, 함수): 각 행에 함수 적용
# apply(counts, 2, 함수): 각 열에 함수 적용

gene_summary <- data.frame(
  gene_id = rownames(counts),
  mean_count = rowMeans(counts),
  median_count = apply(counts, 1, median),
  sd_count = apply(counts, 1, sd),
  detected_samples = rowSums(counts > 0)
)

head(gene_summary)

# 평균 count가 높은 유전자 10개
gene_summary |>
  arrange(desc(mean_count)) |>
  head(10)


# ============================================================
# 6. 시각화를 위한 긴 형태의 데이터 만들기
# ============================================================
# 기존: 한 행에 유전자 하나, 여러 샘플 열
# 변환 후: 한 행에 유전자·샘플 조합 하나
#
# 유전자 5,000개 × 샘플 8개 = 40,000개 행

counts_table <- data.frame(
  gene_id = rownames(counts),
  counts,
  row.names = NULL
)

expression_long <- counts_table |>
  pivot_longer(
    cols = -gene_id,
    names_to = "sample_id",
    values_to = "count"
  )

head(expression_long)
nrow(expression_long)


# ============================================================
# 7. 발현값 분포: 히스토그램
# ============================================================
# x축: count
# y축: 해당 구간에 들어가는 유전자·샘플 조합의 개수

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
# 8. 로그 변환 후 분포 확인하기
# ============================================================
# log2(count + 1)
# 0에도 적용할 수 있도록 1을 더합니다.
# 큰 값의 범위를 압축해 분포를 살펴보기 위한 변환입니다.
# 샘플별 총 count 차이를 보정하는 정규화는 아닙니다.

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
# 9. 샘플별 분포: 박스플롯
# ============================================================
# 샘플 하나의 상자에는 유전자 5,000개의 값이 반영됩니다.
# 상자: 1사분위수 ~ 3사분위수
# 상자 안의 선: 중앙값
# 수염 밖 점: 기본 규칙상 잠재적 이상값이며,
#             자동으로 제거해야 하는 값은 아닙니다.

p_boxplot <- ggplot(
  expression_long,
  aes(x = sample_id, y = log2_count)
) +
  geom_boxplot(fill = "lightblue") +
  labs(
    title = "Expression distribution per sample",
    x = "Sample",
    y = "log2(count + 1)"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_boxplot)


# ============================================================
# 10. 특정 유전자 비교하기
# ============================================================

selected_gene <- "gene1"

selected_data <- expression_long |>
  filter(gene_id == selected_gene)

selected_data

# 선택한 유전자의 기술통계
selected_data |>
  summarise(
    n_samples = n(),
    mean_count = mean(count),
    median_count = median(count),
    sd_count = sd(count)
  )

# 막대 하나는 샘플 하나의 count를 나타냅니다.
p_gene <- ggplot(
  selected_data,
  aes(x = sample_id, y = count)
) +
  geom_col(fill = "darkorange") +
  labs(
    title = selected_gene,
    x = "Sample",
    y = "Raw count"
  ) +
  theme_bw()

print(p_gene)

# 아직 샘플별 총 count를 보정하지 않은 값입니다.
# 이 그림만으로 샘플 간 생물학적 차이를 판단하지 않습니다.


# ============================================================
# 11. 두 샘플의 발현값 비교하기
# ============================================================
# 점 하나는 유전자 하나를 나타냅니다.

sample_comparison <- data.frame(
  gene_id = rownames(counts),
  P1 = counts[, "P1"],
  P2 = counts[, "P2"]
)

p_scatter <- ggplot(
  sample_comparison,
  aes(x = log2(P1 + 1), y = log2(P2 + 1))
) +
  geom_point(alpha = 0.4, size = 1) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    color = "red"
  ) +
  coord_equal() +
  labs(
    title = "Comparison of two samples",
    x = "P1: log2(count + 1)",
    y = "P2: log2(count + 1)"
  ) +
  theme_bw()

print(p_scatter)

# 빨간 점선은 두 샘플의 값이 같은 위치입니다.


# ============================================================
# 12. 결과 저장하기
# ============================================================

write.csv(
  sample_summary,
  "R_class/outputs/sample_summary.csv",
  row.names = FALSE
)

write.csv(
  gene_summary,
  "R_class/outputs/gene_summary.csv",
  row.names = FALSE
)
