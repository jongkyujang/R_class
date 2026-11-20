#!/usr/bin/env bash

FORM_URL="https://docs.google.com/forms/d/e/1FAIpQLSdWTRBTn0IVxO2BoiXIgcZ_yhrLWbiWo3rcW2E2vCKMuydU-w/formResponse"

F_ID="entry.1314529612"     # 학번
F_NAME="entry.1268472269"   # 이름
F_QUIZ1="entry.1893247497"  # 퀴즈 1 결과
F_QUIZ2="entry.412528729"   # 퀴즈 2 결과
F_QUIZ3="entry.2072292314"  # 퀴즈 3 결과
F_QUIZ4="entry.1790634965"  # 퀴즈 4 결과

score=0
total=0
marks=""

hash_answer() {
  local answer="$1"
  answer=${answer//[[:space:]]/}
  printf '%s' "${answer,,}" | sha256sum | cut -d ' ' -f 1
}

ask() {
  local question="$1" expected_hash="$2" answer

  printf '\n%s\n' "$question"
  IFS= read -r -p '답: ' answer || exit 1
  total=$((total + 1))

  if [[ "$(hash_answer "$answer")" == "$expected_hash" ]]; then
    score=$((score + 1))
    marks="${marks}O"
  else
    marks="${marks}X"
  fi
}

if [[ "${1:-}" == "--hash" ]]; then
  IFS= read -r -s -p '정답 입력: ' answer || exit 1
  printf '\n' >&2
  hash_answer "$answer"
  exit 0
fi

# 문항 수정은 여기에서 합니다.
# ask '문제 문장' '정답의 SHA-256 해시'
case "${1:-}" in
  quiz1)
    result_field="$F_QUIZ1"
    echo 'Quiz 1. R 기본 문법'
    ask '1.ages <- c(25, 40, 35, 60, 50)일 때, ages[3]의 결과는? (숫자만)' \
      '9f14025af0065b30e47e23ebb3b491d39ae8ed17d33739e5ff3827ffb3634953'
    ask '2. 같은 ages에서 sum(ages >= 40)의 결과는? (숫자만)' \
      '4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce'
    ;;
  quiz2)
    result_field="$F_QUIZ2"
    echo 'Quiz 2. 데이터 프레임'
    ask '1.patients에서 나이가 50세 이상인 행만 남기려면 select()와 filter() 중 어떤 함수를 쓰나요? 함수 이름만 적으세요. (select/filter 중)' \
      'dfc3376b8266c66e8c24736645128a5f93ccf1df6f381286ffbda654fec8f21c'
    ask 'patients[1:3, c("patient_id", "age")]의 결과에는 열이 몇 개 있나요?(숫자만)' \
      'd4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35'
    ;;
  quiz3)
    result_field="$F_QUIZ3"
    echo 'Quiz 3. RNA 발현 데이터 탐색'
    ask 'counts 행렬의 행은 유전자, 열은 샘플입니다. 샘플별 총 count를 계산할 때 rowSums()와 colSums() 중 어떤 함수를 쓰나요? 함수 이름만 적으세요.' \
      '3fcfc03cd4a9595a7c00cf3369c6fab0609f4064726af1d9eb509f10941e8e10'
    ask '2. 박스플롯 상자 안의 선은 어떤 통계량인가요? (평균/중앙값)' \
      '7cc8adc3a890f367c4f2c8aba73d0b088802a2a387781349f1c3ad1efbe0050f'
    ;;
  quiz4)
    result_field="$F_QUIZ4"
    echo 'Quiz 4. 선형 분류'
    ask '1. 모델이 virginica일 확률을 0.6으로 예측했습니다. 분류 기준을 0.5에서 0.7로 높이면, 이 꽃은 어떤 품종으로 분류될까요? (versicolor / virginica)' \
      '1eb30a01760abb042136843e4185118b70bf7cc0bffecbdbbed862a24a2a5951'
    ask '2. 어떤 직선을 그어도 두 품종을 완벽하게 나눌 수 없다면, 직선 하나를 분류 경계로 쓰는 모델이 이 데이터를 모두 맞힐 수 있나요? (y / n)' \
      '1b16b1df538ba12dc3f97edbb85caa7050d46c148134290feba80f8236c83db9'
    ;;
  *)
    echo '사용법: quiz1 | quiz2 | quiz3 | quiz4'
    exit 2
    ;;
esac

result="$score/$total ($marks)"
printf '\n결과: %s\n' "$result"

quiz="${1:-}"
score_dir="$HOME/.r_class_quiz"

if ! mkdir -p -- "$score_dir" ||
   ! printf '%s\n' "$result" > "$score_dir/$quiz.txt"; then
  echo '퀴즈 결과를 저장하지 못했습니다.'
  exit 1
fi

# 퀴즈 1~3은 점수를 저장하고 종료합니다.
if [[ "$quiz" != "quiz4" ]]; then
  echo '결과를 저장했습니다. 퀴즈 4가 끝나면 한꺼번에 제출합니다.'
  exit 0
fi

# 퀴즈 4가 끝나면 네 퀴즈의 결과를 모두 확인합니다.
for quiz_number in 1 2 3 4; do
  if [[ ! -s "$score_dir/quiz$quiz_number.txt" ]]; then
    printf '퀴즈 %s 결과가 없습니다. quiz%s를 먼저 완료한 뒤 quiz4를 다시 실행하세요.\n' \
      "$quiz_number" "$quiz_number"
    exit 1
  fi
done

printf '\n제출할 결과\n'
for quiz_number in 1 2 3 4; do
  printf '  퀴즈 %s  %s\n' \
    "$quiz_number" "$(<"$score_dir/quiz$quiz_number.txt")"
done

echo '학번, 이름, 퀴즈 1~4 결과를 구글폼으로 제출합니다.'
while true; do
  IFS= read -r -p '학번: ' student_id || exit 1
  IFS= read -r -p '이름: ' student_name || exit 1

  if [[ "$student_id" =~ ^[0-9]+$ && "$student_name" =~ [^[:space:]] ]]; then
    break
  fi
  echo '학번은 숫자로 입력하고 이름을 입력하세요.'
done

if ! status=$(curl --silent --show-error --output /dev/null \
  --write-out '%{http_code}' --max-time 15 "$FORM_URL" \
  --data-urlencode "$F_ID=$student_id" \
  --data-urlencode "$F_NAME=$student_name" \
  --data-urlencode "$F_QUIZ1=$(<"$score_dir/quiz1.txt")" \
  --data-urlencode "$F_QUIZ2=$(<"$score_dir/quiz2.txt")" \
  --data-urlencode "$F_QUIZ3=$(<"$score_dir/quiz3.txt")" \
  --data-urlencode "$F_QUIZ4=$(<"$score_dir/quiz4.txt")"); then
  echo '구글폼에 연결하지 못했습니다. 저장된 퀴즈 결과는 남아 있습니다.'
  exit 1
fi

case "$status" in
  200)
    echo '퀴즈 1~4 결과를 한 건으로 제출 요청했습니다.'
    ;;
  *)
    printf '제출 요청이 실패했습니다 (HTTP %s). 저장된 퀴즈 결과는 남아 있습니다.\n' "$status"
    exit 1
    ;;
esac