# ============================================================
# 04. 선형 분류와 시각화
# ============================================================
# 학습 목표
# - 두 가지 측정값을 사용해 두 그룹을 분류하기
# - 학습용 데이터로 모델을 만들고 평가용 데이터로 예측하기
# - 실제 그룹과 예측 그룹을 산점도에서 비교하기
#
# 실행: Cmd + Enter (Mac) / Ctrl + Enter (Windows)

library(tidyverse)


# ============================================================
# 1. 데이터 준비하기
# ============================================================
# 한 행은 붓꽃 한 송이입니다.
# 입력값: 꽃잎 길이(Petal.Length), 꽃잎 너비(Petal.Width)
# 정답: 품종(Species)

flowers <- iris |>
  filter(Species %in% c("versicolor", "virginica")) |>
  select(Petal.Length, Petal.Width, Species) |>
  mutate(
    # virginica는 1, versicolor는 0으로 표시합니다.
    is_virginica = ifelse(Species == "virginica", 1, 0)
  )

head(flowers)
table(flowers$Species)


# ============================================================
# 2. 학습용 데이터와 평가용 데이터 나누기
# ============================================================
# 품종마다 35개는 학습에 사용하고, 나머지 15개는 평가에 사용합니다.
# set.seed()를 지정하면 다시 실행해도 같은 방식으로 나뉩니다.

set.seed(123)

train_rows <- c(
  sample(which(flowers$Species == "versicolor"), 35),
  sample(which(flowers$Species == "virginica"), 35)
)

train <- flowers[train_rows, ]
test <- flowers[-train_rows, ]

table(train$Species)
table(test$Species)


# ============================================================
# 3. 로지스틱 회귀 모델 만들기
# ============================================================
# 꽃잎 길이와 너비를 사용해 virginica일 확률을 계산합니다.
# 두 품종을 나누는 경계는 이 산점도에서 직선입니다.

model <- glm(
  is_virginica ~ Petal.Length + Petal.Width,
  data = train,
  family = binomial()
)

coef(model)


# ============================================================
# 4. 평가용 데이터의 품종 예측하기
# ============================================================
# 예측 확률이 0.5 이상이면 virginica로 분류합니다.

test$prob_virginica <- predict(
  model,
  newdata = test,
  type = "response"
)

test$predicted_species <- ifelse(
  test$prob_virginica >= 0.5,
  "virginica",
  "versicolor"
)

test$correct <- test$Species == test$predicted_species

head(test)

# 행은 실제 품종, 열은 예측 품종입니다.
table(Actual = test$Species, Predicted = test$predicted_species)

# 정확도는 전체 평가용 데이터에서 맞힌 비율입니다.
mean(test$correct)

# 틀린 사례의 길이, 너비, 예측 확률을 확인합니다.
test[!test$correct, ]


# ============================================================
# 5. 실제 품종과 예측 품종을 산점도로 비교하기
# ============================================================
# 왼쪽과 오른쪽에는 같은 평가용 데이터가 표시됩니다.
# 색이 바뀐 점은 모델이 품종을 틀리게 예측한 꽃입니다.

plot_data <- test |>
  transmute(
    Petal.Length,
    Petal.Width,
    Actual = as.character(Species),
    Predicted = predicted_species
  ) |>
  pivot_longer(
    cols = c(Actual, Predicted),
    names_to = "panel",
    values_to = "species"
  )

# 예측 확률이 0.5인 지점을 연결한 선이 분류 경계입니다.
# b0 + b1 * 길이 + b2 * 너비 = 0을 너비에 대해 정리합니다.
b <- coef(model)
boundary_slope <- -b[["Petal.Length"]] / b[["Petal.Width"]]
boundary_intercept <- -b[["(Intercept)"]] / b[["Petal.Width"]]

p_classifier <- ggplot(
  plot_data,
  aes(x = Petal.Length, y = Petal.Width, color = species)
) +
  geom_point(size = 3, alpha = 0.8) +
  geom_abline(
    slope = boundary_slope,
    intercept = boundary_intercept,
    linetype = "dashed"
  ) +
  facet_wrap(~ panel) +
  labs(
    title = "Actual vs. predicted species",
    x = "Petal length (cm)",
    y = "Petal width (cm)",
    color = "Species"
  ) +
  theme_bw()

print(p_classifier)