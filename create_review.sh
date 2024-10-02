#!/bin/bash



DATE=$(date +"%Y-%m-%d")
REVIEW_DIR="reviews/$DATE"

if [ ! -d ".git" ]; then
    echo "Error: You have to run the script from a Git repository root."
    exit 1
fi


mkdir -p "$REVIEW_DIR"


INCLUDE_EXTENSIONS=("py" "js" "html")  

EXCLUDE_DIRS=("reviews" ".git" "node_modules" "__pycache__" ".venv" ".test")  # Добавьте директории, которые следует исключить


FIND_CMD="find ."
for ext in "${INCLUDE_EXTENSIONS[@]}"; do
    FIND_CMD+=" -type f -name '*.${ext}' -o"
done
FIND_CMD=${FIND_CMD% -o}  


for dir in "${EXCLUDE_DIRS[@]}"; do
    FIND_CMD+=" ! -path './${dir}/*'"
done


FILES=$(eval $FIND_CMD)

if [ -z "$FILES" ]; then
  echo "No files found for review!"
  exit 0
fi


for FILE in $FILES; do
  content=$(cat "$FILE")
  prompt="\nReview this code, provide suggestions for improvement, coding best practices, improve readability, and maintainability. Remove any code smells and anti-patterns. Provide code examples for your suggestion. Respond in markdown format. If the file does not have any code or does not need any changes, say 'No changes needed'."

  suggestions=$(ollama run codellama "Code: $content $prompt")

  REVIEW_FILE="$REVIEW_DIR/$(basename "$FILE").review.md"

  echo "## Review for $FILE" > "$REVIEW_FILE"
  echo "" >> "$REVIEW_FILE"
  echo "$suggestions" >> "$REVIEW_FILE"
  echo "" >> "$REVIEW_FILE"
  echo "---" >> "$REVIEW_FILE"
  echo "" >> "$REVIEW_FILE"
done

echo "Code review completed successfully! Reviews are saved in the '$REVIEW_DIR' directory."
