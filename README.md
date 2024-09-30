# Git Pre-Commit Code Review Hook

## Overview

This repository contains a script (`setup_precommit.sh`) to set up a Git pre-commit hook that automatically performs a code review on all modified Python files before committing. The pre-commit hook leverages the `Ollama` language model to provide suggestions for improving code quality, best practices, readability, and maintainability.

## Features

- **Automated Code Review**: Runs a code review on all staged Python files using `Ollama`'s `codellama` model.
- **Markdown Output**: The review suggestions are saved in a `review.md` file in markdown format for easy reading.

## Installation

To set up the pre-commit hook in your Git repository, run the following command:

```sh
chmod +x setup_precommit.sh
./setup_precommit.sh
