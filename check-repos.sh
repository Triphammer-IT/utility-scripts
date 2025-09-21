#!/bin/bash

# Repository Status Checker and Batch Manager
# Recursively checks all git repositories for uncommitted/unpushed changes
# and offers batch commit/push operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global arrays to track repos with changes
declare -a repos_with_uncommitted=()
declare -a repos_with_unpushed=()
declare -a repos_with_both=()

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a directory is a git repository
is_git_repo() {
    local dir=$1
    [[ -d "$dir/.git" ]]
}

# Function to check repository status
check_repo_status() {
    local repo_path=$1
    local repo_name
    repo_name=$(basename "$repo_path")
    local has_uncommitted=false
    local has_unpushed=false

    cd "$repo_path"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        has_uncommitted=true
    fi

    # Check for unpushed commits
    if git rev-list --count HEAD ^origin/HEAD 2>/dev/null | grep -q "^[1-9]"; then
        has_unpushed=true
    fi

    # Categorize the repo
    if [[ "$has_uncommitted" == true && "$has_unpushed" == true ]]; then
        repos_with_both+=("$repo_path")
    elif [[ "$has_uncommitted" == true ]]; then
        repos_with_uncommitted+=("$repo_path")
    elif [[ "$has_unpushed" == true ]]; then
        repos_with_unpushed+=("$repo_path")
    fi
}

# Function to recursively find and check git repositories
scan_repositories() {
    local base_dir=$1
    local depth=${2:-0}

    # Limit recursion depth to prevent infinite loops
    if [[ $depth -gt 10 ]]; then
        return
    fi

    for item in "$base_dir"/*; do
        if [[ -d "$item" ]]; then
            # Skip .git directories and other common non-repo directories
            local dirname
            dirname=$(basename "$item")
            if [[ "$dirname" == ".git" || "$dirname" == "node_modules" || "$dirname" == ".venv" ]]; then
                continue
            fi

            if is_git_repo "$item"; then
                print_status "$BLUE" "Checking repository: $item"
                check_repo_status "$item"
            else
                # Recursively check subdirectories
                scan_repositories "$item" $((depth + 1))
            fi
        fi
    done
}

# Function to display summary of changes
display_summary() {
    print_status "$YELLOW" "\n=== REPOSITORY STATUS SUMMARY ==="

    if [[ ${#repos_with_both[@]} -eq 0 && ${#repos_with_uncommitted[@]} -eq 0 && ${#repos_with_unpushed[@]} -eq 0 ]]; then
        print_status "$GREEN" "✅ All repositories are clean and up to date!"
        return 0
    fi

    if [[ ${#repos_with_both[@]} -gt 0 ]]; then
        print_status "$RED" "\n📝 Repositories with BOTH uncommitted changes AND unpushed commits:"
        for repo in "${repos_with_both[@]}"; do
            echo "  - $repo"
        done
    fi

    if [[ ${#repos_with_uncommitted[@]} -gt 0 ]]; then
        print_status "$YELLOW" "\n📝 Repositories with uncommitted changes:"
        for repo in "${repos_with_uncommitted[@]}"; do
            echo "  - $repo"
        done
    fi

    if [[ ${#repos_with_unpushed[@]} -gt 0 ]]; then
        print_status "$BLUE" "\n📤 Repositories with unpushed commits:"
        for repo in "${repos_with_unpushed[@]}"; do
            echo "  - $repo"
        done
    fi

    return 1
}

# Function to commit and push changes for a repository
commit_and_push_repo() {
    local repo_path=$1
    local repo_name
    repo_name=$(basename "$repo_path")

    cd "$repo_path"

    print_status "$BLUE" "Processing: $repo_name"

    # Check if there are uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_status "$YELLOW" "  Adding and committing changes..."
        git add .
        git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    # Check if there are commits to push
    if git rev-list --count HEAD ^origin/HEAD 2>/dev/null | grep -q "^[1-9]"; then
        print_status "$YELLOW" "  Pushing to origin..."
        git push origin HEAD
    fi

    print_status "$GREEN" "  ✅ $repo_name completed"
}

# Function to handle batch operations
handle_batch_operations() {
    local all_repos=()

    # Safely combine arrays, handling empty arrays
    if [[ ${#repos_with_both[@]} -gt 0 ]]; then
        all_repos+=("${repos_with_both[@]}")
    fi
    if [[ ${#repos_with_uncommitted[@]} -gt 0 ]]; then
        all_repos+=("${repos_with_uncommitted[@]}")
    fi
    if [[ ${#repos_with_unpushed[@]} -gt 0 ]]; then
        all_repos+=("${repos_with_unpushed[@]}")
    fi

    if [[ ${#all_repos[@]} -eq 0 ]]; then
        return
    fi

    print_status "$YELLOW" "\n=== BATCH OPERATIONS ==="
    echo "Would you like to commit and push changes?"
    echo "1) Process ALL repositories"
    echo "2) SELECT specific repositories"
    echo "3) Skip batch operations"

    read -rp "Enter your choice (1-3): " choice

    case $choice in
        1)
            print_status "$GREEN" "Processing all repositories..."
            for repo in "${all_repos[@]}"; do
                commit_and_push_repo "$repo"
            done
            ;;
        2)
            print_status "$YELLOW" "Select repositories to process:"
            for i in "${!all_repos[@]}"; do
                echo "$((i+1))) ${all_repos[$i]}"
            done
            echo "Enter repository numbers (space-separated) or 'all' for all:"
            read -rp "Selection: " selection

            if [[ "$selection" == "all" ]]; then
                for repo in "${all_repos[@]}"; do
                    commit_and_push_repo "$repo"
                done
            else
                for num in $selection; do
                    if [[ $num -ge 1 && $num -le ${#all_repos[@]} ]]; then
                        commit_and_push_repo "${all_repos[$((num-1))]}"
                    fi
                done
            fi
            ;;
        3)
            print_status "$BLUE" "Skipping batch operations."
            ;;
        *)
            print_status "$RED" "Invalid choice. Skipping batch operations."
            ;;
    esac
}

# Function to show detailed status for a repository
show_detailed_status() {
    local repo_path=$1
    local repo_name
    repo_name=$(basename "$repo_path")

    cd "$repo_path"

    print_status "$BLUE" "\n--- Detailed Status: $repo_name ---"

    # Show current branch
    local current_branch
    current_branch=$(git branch --show-current)
    print_status "$YELLOW" "Current branch: $current_branch"

    # Show uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_status "$RED" "Uncommitted changes:"
        git status --short
    fi

    # Show unpushed commits
    local unpushed_count
    unpushed_count=$(git rev-list --count HEAD ^origin/HEAD 2>/dev/null || echo "0")
    if [[ "$unpushed_count" -gt 0 ]]; then
        print_status "$BLUE" "Unpushed commits: $unpushed_count"
        git log --oneline origin/HEAD..HEAD 2>/dev/null || true
    fi
}

# Function to show help
show_help() {
    echo "Repository Status Checker and Batch Manager"
    echo ""
    echo "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --detailed Show detailed status for each repository"
    echo ""
    echo "Arguments:"
    echo "  DIRECTORY      Directory to scan (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check current directory"
    echo "  $0 /path/to/repos     # Check specific directory"
    echo "  $0 -d                 # Show detailed status"
}

# Main function
main() {
    local base_dir="."
    local detailed=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--detailed)
                detailed=true
                shift
                ;;
            -*)
                print_status "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                base_dir="$1"
                shift
                ;;
        esac
    done

    # Convert to absolute path
    base_dir=$(realpath "$base_dir")

    if [[ ! -d "$base_dir" ]]; then
        print_status "$RED" "Error: Directory '$base_dir' does not exist"
        exit 1
    fi

    print_status "$BLUE" "🔍 Scanning for git repositories in: $base_dir"

    # Scan repositories
    scan_repositories "$base_dir"

    # Display summary
    if ! display_summary; then
        # Show detailed status if requested
        if [[ "$detailed" == true ]]; then
            local all_repos=()

            # Safely combine arrays, handling empty arrays
            if [[ ${#repos_with_both[@]} -gt 0 ]]; then
                all_repos+=("${repos_with_both[@]}")
            fi
            if [[ ${#repos_with_uncommitted[@]} -gt 0 ]]; then
                all_repos+=("${repos_with_uncommitted[@]}")
            fi
            if [[ ${#repos_with_unpushed[@]} -gt 0 ]]; then
                all_repos+=("${repos_with_unpushed[@]}")
            fi

            for repo in "${all_repos[@]}"; do
                show_detailed_status "$repo"
            done
        fi

        # Handle batch operations
        handle_batch_operations
    fi

    print_status "$GREEN" "\n🎉 Repository check completed!"
}

# Run main function with all arguments
main "$@"
