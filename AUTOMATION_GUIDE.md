# Whitespace Linting Automation Guide

This guide shows you how to automate whitespace linting in various ways, from simple git hooks to full CI/CD integration.

## 🚀 Quick Start

### Option 1: Pre-commit Hook (Recommended)
```bash
# Basic setup (check only)
./setup-pre-commit.sh

# Setup with auto-fix
./setup-pre-commit.sh -f

# Check only specific file types
./setup-pre-commit.sh -e sh,py,js

# Ignore certain files
./setup-pre-commit.sh -i '*.log,*.tmp'
```

### Option 2: Pre-commit Framework
```bash
# Install pre-commit framework
pip install pre-commit

# Setup with our configuration
./setup-pre-commit.sh --framework
```

## 📋 Automation Options

### 1. Git Hooks (Native)

#### Pre-commit Hook
Runs before each commit, preventing commits with whitespace issues.

**Setup:**
```bash
./setup-pre-commit.sh
```

**Features:**
- Checks only staged files (fast)
- Prevents commits with issues
- Optional auto-fix mode
- Configurable file types and patterns

#### Pre-push Hook
Runs before pushing, ensuring the entire repository is clean.

**Setup:**
```bash
./setup-pre-commit.sh  # Creates both pre-commit and pre-push hooks
```

**Features:**
- Checks entire repository
- Prevents pushing with issues
- Good for team consistency

### 2. Pre-commit Framework

A more sophisticated approach using the pre-commit framework.

**Setup:**
```bash
pip install pre-commit
./setup-pre-commit.sh --framework
```

**Features:**
- More hooks available
- Better configuration management
- Can run multiple linters
- Supports different stages (pre-commit, pre-push, etc.)

### 3. CI/CD Integration

#### GitHub Actions
Add the provided workflow to `.github/workflows/whitespace-lint.yml`:

```yaml
# See github-actions-whitespace.yml for full example
name: Whitespace Linting
on: [push, pull_request]
jobs:
  whitespace-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run whitespace linter
        run: |
          git clone https://github.com/Triphammer-IT/utility-scripts.git /tmp/utility-scripts
          /tmp/utility-scripts/whitespace-linter.sh -r .
```

**Features:**
- Runs on every push/PR
- Comments on PRs with issues
- Can auto-fix issues
- Integrates with team workflow

#### GitLab CI
```yaml
# .gitlab-ci.yml
whitespace-lint:
  stage: test
  script:
    - git clone https://github.com/Triphammer-IT/utility-scripts.git /tmp/utility-scripts
    - /tmp/utility-scripts/whitespace-linter.sh -r .
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

#### Jenkins
```groovy
pipeline {
    agent any
    stages {
        stage('Whitespace Lint') {
            steps {
                sh '''
                    git clone https://github.com/Triphammer-IT/utility-scripts.git /tmp/utility-scripts
                    /tmp/utility-scripts/whitespace-linter.sh -r .
                '''
            }
        }
    }
}
```

### 4. Editor Integration

#### VS Code
Add to your `settings.json`:
```json
{
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "editor.rulers": [80, 120],
    "editor.renderWhitespace": "all"
}
```

#### Vim/Neovim
Add to your `.vimrc`:
```vim
" Show whitespace
set list
set listchars=tab:→\ ,trail:·,nbsp:·

" Auto-remove trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Show trailing whitespace
highlight TrailingWhitespace ctermbg=red guibg=red
match TrailingWhitespace /\s\+$/
```

#### Emacs
Add to your `.emacs`:
```elisp
;; Show whitespace
(global-whitespace-mode t)
(setq whitespace-style '(face trailing tabs spaces))

;; Auto-remove trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)
```

### 5. Cron Jobs

For regular repository maintenance:

```bash
# Add to crontab (crontab -e)
# Check all repos daily at 2 AM
0 2 * * * /path/to/utility-scripts/check-repos.sh -r /path/to/all/repos

# Fix whitespace issues weekly
0 3 * * 0 /path/to/utility-scripts/whitespace-linter.sh -f -r /path/to/all/repos
```

### 6. Makefile Integration

```makefile
# Makefile
.PHONY: lint-whitespace fix-whitespace

lint-whitespace:
	./utility-scripts/whitespace-linter.sh -r .

fix-whitespace:
	./utility-scripts/whitespace-linter.sh -f -r .

lint: lint-whitespace
	# Add other linters here

fix: fix-whitespace
	# Add other fixers here
```

## 🎯 Best Practices

### 1. Layered Approach
Use multiple automation levels:
- **Editor**: Fix as you type
- **Pre-commit**: Catch before commit
- **CI/CD**: Ensure team consistency
- **Cron**: Regular maintenance

### 2. Team Onboarding
```bash
# Create a setup script for new team members
#!/bin/bash
echo "Setting up whitespace linting..."

# Install pre-commit
pip install pre-commit

# Setup hooks
./utility-scripts/setup-pre-commit.sh -f

# Configure editor
echo "Don't forget to configure your editor to show whitespace!"

echo "✅ Setup complete!"
```

### 3. Gradual Rollout
1. Start with CI/CD (non-blocking)
2. Add pre-commit hooks (optional)
3. Make pre-commit hooks required
4. Add editor integration

### 4. Configuration Management
```bash
# Create a .whitespace-config file
cat > .whitespace-config << EOF
extensions=sh,py,js,ts,html,css,md,txt,yml,yaml,json,xml
ignore_patterns=*.log,*.tmp,*.bak,node_modules/**,.git/**
check_trailing=true
check_whitespace_only=true
EOF

# Use in scripts
source .whitespace-config
./whitespace-linter.sh -e "$extensions" -i "$ignore_patterns" -r .
```

## 🔧 Troubleshooting

### Common Issues

#### Hook Not Running
```bash
# Check hook permissions
ls -la .git/hooks/pre-commit

# Make executable if needed
chmod +x .git/hooks/pre-commit
```

#### Performance Issues
```bash
# Use file extensions to limit scope
./whitespace-linter.sh -e sh,py,js -r .

# Ignore large directories
./whitespace-linter.sh -i 'node_modules/**,.git/**,build/**' -r .
```

#### False Positives
```bash
# Exclude specific patterns
./whitespace-linter.sh -i '*.min.js,*.bundle.js' -r .

# Use different check types
./whitespace-linter.sh --no-whitespace-only -r .
```

## 📊 Monitoring

### Track Issues Over Time
```bash
# Create a monitoring script
#!/bin/bash
REPO_DIR="/path/to/repos"
LOG_FILE="/var/log/whitespace-lint.log"

echo "$(date): Starting whitespace check" >> "$LOG_FILE"

for repo in "$REPO_DIR"/*; do
    if [[ -d "$repo/.git" ]]; then
        issues=$(./utility-scripts/whitespace-linter.sh -q -r "$repo" 2>&1 | grep "Total issues found" | cut -d: -f2 | tr -d ' ')
        echo "$(date): $repo: $issues issues" >> "$LOG_FILE"
    fi
done
```

### Generate Reports
```bash
# Weekly report script
#!/bin/bash
echo "# Whitespace Lint Report - $(date)"
echo ""

for repo in /path/to/repos/*; do
    if [[ -d "$repo/.git" ]]; then
        echo "## $(basename "$repo")"
        ./utility-scripts/whitespace-linter.sh -r "$repo" | grep -E "(Files processed|Total issues found)"
        echo ""
    fi
done
```

## 🚀 Advanced Usage

### Custom Hook Scripts
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run whitespace linter
./utility-scripts/whitespace-linter.sh -r .

# Run other linters
./utility-scripts/check-repos.sh

# Run tests
make test

# All must pass
exit $?
```

### Integration with Other Tools
```bash
# Combine with other linters
#!/bin/bash
echo "Running all linters..."

# Whitespace
./utility-scripts/whitespace-linter.sh -r .

# Shell scripts
shellcheck **/*.sh

# Python
flake8 **/*.py

# JavaScript
eslint **/*.js

echo "All linters passed!"
```

This guide provides comprehensive automation options for whitespace linting. Choose the approach that best fits your workflow and team needs!
