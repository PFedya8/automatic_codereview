#!/bin/bash

CONFIG_FILE="config.cfg"

# Function to load configuration from file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Loading configuration from $CONFIG_FILE..."

        # Read target directory from config
        TARGET_DIR=$(grep -E '^target_dir=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '\0')
        
        # Read extensions to include from config
        INCLUDE_EXTENSIONS=$(grep -E '^include_extensions=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '\0')
        if [ -n "$INCLUDE_EXTENSIONS" ]; then
            IFS=',' read -ra INCLUDE_EXTENSIONS <<< "$INCLUDE_EXTENSIONS"
        else
            INCLUDE_EXTENSIONS=()
        fi

        # Read directories to exclude from config
        EXCLUDE_DIRS=$(grep -E '^exclude_dirs=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '\0')
        if [ -n "$EXCLUDE_DIRS" ]; then
            IFS=',' read -ra EXCLUDE_DIRS <<< "$EXCLUDE_DIRS"
        else
            EXCLUDE_DIRS=()
        fi
    else
        echo "No configuration file found. Proceeding with manual input..."
        TARGET_DIR=""
        INCLUDE_EXTENSIONS=()
        EXCLUDE_DIRS=()
    fi
}

# Load configuration from file if it exists
load_config

# Get the directory to run the script from, prompt if not set in config
if [ -z "$TARGET_DIR" ]; then
    read -p "Enter the directory to run the script from: " TARGET_DIR
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: The specified directory does not exist."
  exit 1
fi

# Prompt for file extensions if not provided in the config
if [ ${#INCLUDE_EXTENSIONS[@]} -eq 0 ]; then
    read -p "Enter the file extensions to include (comma separated, or 'all' for all files): " EXTENSIONS_INPUT

    if [ "$EXTENSIONS_INPUT" == "all" ]; then
        INCLUDE_EXTENSIONS=("*")
    else
        IFS=',' read -ra INCLUDE_EXTENSIONS <<< "$EXTENSIONS_INPUT"
    fi
fi

# Handle "all files" case with `*`
if [ "${INCLUDE_EXTENSIONS[0]}" == "*" ]; then
    FIND_CMD="find $TARGET_DIR -type f"
else
    # Construct the find command to include extensions
    FIND_CMD="find $TARGET_DIR"
    for ext in "${INCLUDE_EXTENSIONS[@]}"; do
        FIND_CMD+=" -type f -name '*.${ext}' -o"
    done
    FIND_CMD=${FIND_CMD% -o}  # Remove the trailing -o
fi

# Prompt for excluded directories if not provided in the config
if [ ${#EXCLUDE_DIRS[@]} -eq 0 ]; then
    read -p "Enter the directories to exclude (comma separated, or press Enter to use default exclusions): " EXCLUDE_INPUT

    if [ -z "$EXCLUDE_INPUT" ]; then
        EXCLUDE_DIRS=("reviews" ".git" "node_modules" "__pycache__" ".venv" ".test")  # Default directories to exclude
    else
        IFS=',' read -ra EXCLUDE_DIRS <<< "$EXCLUDE_INPUT"
    fi
fi

DATE=$(date +"%Y-%m-%d")
REVIEW_DIR="$TARGET_DIR/reviews/$DATE"

mkdir -p "$REVIEW_DIR"

# Add exclusion of directories
for dir in "${EXCLUDE_DIRS[@]}"; do
  FIND_CMD+=" ! -path '$TARGET_DIR/${dir}/*'"
done

# Execute the find command and get the files
FILES=$(eval $FIND_CMD)

if [ -z "$FILES" ]; then
  echo "No files found for review!"
  exit 0
fi

# Loop through each file and create the review
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
