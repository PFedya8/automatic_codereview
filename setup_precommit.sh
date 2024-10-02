#!/bin/bash

# setup_precommit.sh
if ! command -v ollama &> /dev/null; then
    echo "Ollama is not installed. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi
ollama pull codellama

HOOK_FILE=".git/hooks/pre-commit"


if [ ! -d ".git" ]; then
    echo "Errro: You have to run script from Git repo"
    exit 1
fi


cat <<EOL > $HOOK_FILE
#!/bin/sh


FILES=\$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$')

if [ -z "\$FILES" ]; then
  echo "There are no new files to review!"
  exit 0
fi


> review.md


for FILE in \$FILES; do
  content=\$(cat "\$FILE")
  prompt="\nReview this code, provide suggestions for improvement, coding best practices, improve readability, and maintainability. Remove any code smells and anti-patterns. Provide code examples for your suggestion. Respond in markdown format. If the file does not have any code or does not need any changes, say 'No changes needed'."

  # Uncomment next line to run it in docker
  #suggestions=\$(docker exec ollama ollama run codellama "Code: \$content \$prompt")
  suggestions=\$(ollama run codellama "Code: \$content \$prompt")


  echo "## Review for \$FILE" >> review.md
  echo "" >> review.md
  echo "\$suggestions" >> review.md
  echo "" >> review.md
  echo "---" >> review.md
  echo "" >> review.md
done

echo "Code riview was done successfully!"
exit 0
EOL


chmod +x $HOOK_FILE

echo "Pre-commit hook installation successful."
