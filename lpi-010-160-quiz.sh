#!/bin/bash

CSV_FILE="lpi_questions_clean.csv"

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: $CSV_FILE not found!"
    echo "Please put the CSV file in the same directory."
    exit 1
fi

clear
echo "========================================"
echo "   LPI 010-160 Linux Essentials Quiz"
echo "========================================"

declare -a qnum question options correct qtype

echo "Loading questions..."

while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^question_num ]] && continue
    [[ -z "$line" ]] && continue

    q=$(echo "$line" | cut -d',' -f1 | sed 's/"//g;s/^ *//;s/ *$//')
    quest=$(echo "$line" | cut -d',' -f2 | sed 's/"//g;s/^ *//;s/ *$//')
    opt=$(echo "$line" | cut -d',' -f3- | rev | cut -d',' -f3- | rev | sed 's/"//g;s/^ *//;s/ *$//')
    corr=$(echo "$line" | rev | cut -d',' -f2 | rev | sed 's/"//g;s/^ *//;s/ *$//')
    typ=$(echo "$line" | rev | cut -d',' -f1 | rev | sed 's/"//g;s/^ *//;s/ *$//')

    [[ -z "$quest" ]] && continue

    qnum+=("$q")
    question+=("$quest")
    options+=("$opt")
    correct+=("$corr")
    qtype+=("$typ")
done < "$CSV_FILE"

total=${#qnum[@]}
echo "✅ Loaded $total questions."


indices=($(seq 0 $((${#question[@]}-1))))
shuffled=($(shuf -e "${indices[@]}"))

score=0
wrong=0

echo "========================================"
echo "   Quiz Started - Good Luck!"
echo "========================================"

for idx in "${shuffled[@]}"; do
    printf '\033[2J\033[H'

    echo "========================================"
    echo "Question ${qnum[$idx]}"
    echo "${question[$idx]}"
    echo ""
    [ -n "${options[$idx]}" ] && echo "${options[$idx]}"
    echo ""

    read -r user_input

    if [[ ${user_input,,} == "q" ]]; then
        printf '\033[2J\033[H'
        echo "Quiz terminated."
        break
    fi

    current_type="${qtype[$idx]}"

    if [[ "$current_type" == *"Dual"* || "$current_type" == *"dual"* || \
          "$current_type" == *"Triple"* || "$current_type" == *"triple"* ]]; then

        user_answer=$(echo "$user_input" | tr -dc 'A-Ea-e' | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        clean_correct=$(echo "${correct[$idx]}" | tr -dc 'A-Ea-e' | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        if [[ "$user_answer" == "$clean_correct" ]]; then
            echo "✅ Correct!"
            score=$((score + 1))
        else
            echo "❌ Wrong. Correct: ${correct[$idx]}"
            wrong=$((wrong + 1))
        fi

    elif [[ "$current_type" == *"Blank"* || "$current_type" == *"blank"* ]]; then

        if [[ -z "$user_input" ]]; then
            echo "❌ Wrong. (You entered nothing)"
            wrong=$((wrong + 1))
        elif [[ "$user_input" == "${correct[$idx]}" ]] || [[ "${user_input,,}" == "${correct[$idx],,}" ]]; then
            echo "✅ Correct!"
            score=$((score + 1))
        else
            echo "❌ Wrong. Correct answer: ${correct[$idx]}"
            wrong=$((wrong + 1))
        fi

    else

        user_answer=$(echo "$user_input" | tr -dc 'A-Ea-e' | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        clean_correct=$(echo "${correct[$idx]}" | tr -dc 'A-Ea-e' | tr '[:lower:]' '[:upper:]' | tr -d ' ')
        if [[ "$user_answer" == "$clean_correct" ]]; then
            echo "✅ Correct!"
            score=$((score + 1))
        else
            echo "❌ Wrong. Correct answer: ${correct[$idx]}"
            wrong=$((wrong + 1))
        fi
    fi

    answered=$((score + wrong))
    echo "========================================"
    echo "Score → $score correct | $wrong wrong | $answered/$total"
    echo "========================================"
    read -p "Press Enter for next question..."
done

printf '\033[2J\033[H'
echo -e "\n========== QUIZ FINISHED =========="
echo "Final Score: $score / $total correct"
echo "Wrong answers: $wrong"
if [ $total -gt 0 ]; then
    percent=$((score * 100 / total))
    echo "Percentage: $percent%"
fi
echo "===================================="

