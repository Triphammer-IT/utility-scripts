#!/bin/bash

# Whitespace Maintenance Script
# Designed to run as a cron job for regular repository maintenance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-/var/log/whitespace-maintenance.log}"
REPO_DIRS="${REPO_DIRS:-/Users/john/code/git-repos/mine}"
AUTO_FIX="${AUTO_FIX:-false}"
EMAIL_REPORT="${EMAIL_REPORT:-false}"
EMAIL_ADDRESS="${EMAIL_ADDRESS:-}"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to log with timestamp
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" | tee -a "$LOG_FILE"
}

# Function to show help
show_help() {
    echo "Whitespace Maintenance Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -d, --dirs DIRS      Comma-separated list of directories to check"
    echo "  -f, --fix            Automatically fix whitespace issues"
    echo "  -l, --log FILE       Log file path (default: /var/log/whitespace-maintenance.log)"
    echo "  -e, --email ADDR     Email address for reports"
    echo "  -q, --quiet          Quiet mode (minimal output)"
    echo ""
    echo "Environment Variables:"
    echo "  REPO_DIRS            Directories to check (default: /Users/john/code/git-repos/mine)"
    echo "  AUTO_FIX             Set to 'true' to auto-fix issues"
    echo "  LOG_FILE             Log file path"
    echo "  EMAIL_REPORT         Set to 'true' to email reports"
    echo "  EMAIL_ADDRESS        Email address for reports"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Check default directories"
    echo "  $0 -d /path/to/repos                 # Check specific directory"
    echo "  $0 -f                                # Auto-fix issues"
    echo "  $0 -e user@example.com               # Email reports"
    echo ""
    echo "Cron Examples:"
    echo "  # Check daily at 2 AM"
    echo "  0 2 * * * $0"
    echo ""
    echo "  # Fix issues weekly on Sunday at 3 AM"
    echo "  0 3 * * 0 $0 -f"
    echo ""
    echo "  # Check and email reports daily"
    echo "  0 2 * * * $0 -e admin@company.com"
}

# Function to check a single repository
check_repository() {
    local repo_path=$1
    local repo_name
    repo_name=$(basename "$repo_path")
    
    if [[ ! -d "$repo_path/.git" ]]; then
        return 0
    fi
    
    log_message "Checking repository: $repo_name"
    
    # Change to repository directory
    cd "$repo_path"
    
    # Run whitespace linter
    local linter_output
    linter_output=$("$SCRIPT_DIR/whitespace-linter.sh" -q -r . 2>&1 || true)
    
    # Parse output for issue count
    local issues_count
    issues_count=$(echo "$linter_output" | grep "Total issues found" | cut -d: -f2 | tr -d ' ' || echo "0")
    
    if [[ "$issues_count" -gt 0 ]]; then
        log_message "Repository $repo_name has $issues_count whitespace issues"
        
        if [[ "$AUTO_FIX" == "true" ]]; then
            log_message "Auto-fixing issues in $repo_name"
            if "$SCRIPT_DIR/whitespace-linter.sh" -f -r .; then
                log_message "Successfully fixed issues in $repo_name"
                
                # Commit the fixes if there are changes
                if ! git diff --quiet; then
                    git add .
                    git commit -m "Auto-fix whitespace issues

                    - Remove trailing whitespace
                    - Convert whitespace-only lines to empty lines
                    - Fixed by whitespace-maintenance.sh on $(date)"
                    
                    # Push if there's a remote
                    if git remote | grep -q .; then
                        git push
                        log_message "Pushed whitespace fixes for $repo_name"
                    fi
                fi
            else
                log_message "Failed to fix issues in $repo_name"
            fi
        fi
        
        return 1
    else
        log_message "Repository $repo_name is clean"
        return 0
    fi
}

# Function to generate report
generate_report() {
    local total_repos=0
    local repos_with_issues=0
    local total_issues=0
    
    echo "# Whitespace Maintenance Report"
    echo "Generated: $(date)"
    echo ""
    
    # Parse log file for statistics
    if [[ -f "$LOG_FILE" ]]; then
        total_repos=$(grep -c "Checking repository:" "$LOG_FILE" || echo "0")
        repos_with_issues=$(grep -c "has.*whitespace issues" "$LOG_FILE" || echo "0")
        total_issues=$(grep "has.*whitespace issues" "$LOG_FILE" | sed 's/.*has \([0-9]*\) whitespace issues.*/\1/' | awk '{sum += $1} END {print sum}' || echo "0")
    fi
    
    echo "## Summary"
    echo "- Total repositories checked: $total_repos"
    echo "- Repositories with issues: $repos_with_issues"
    echo "- Total issues found: $total_issues"
    echo ""
    
    if [[ "$repos_with_issues" -gt 0 ]]; then
        echo "## Repositories with Issues"
        grep "has.*whitespace issues" "$LOG_FILE" | sed 's/.*: Repository /- /' || true
        echo ""
    fi
    
    if [[ "$AUTO_FIX" == "true" ]]; then
        echo "## Auto-fix Results"
        grep "Successfully fixed" "$LOG_FILE" | sed 's/.*: Successfully fixed /- /' || echo "- No fixes applied"
        echo ""
    fi
    
    echo "## Recommendations"
    if [[ "$repos_with_issues" -gt 0 ]]; then
        echo "- Consider setting up pre-commit hooks to prevent future issues"
        echo "- Run the linter regularly to catch issues early"
        if [[ "$AUTO_FIX" != "true" ]]; then
            echo "- Use the -f flag to automatically fix issues"
        fi
    else
        echo "- All repositories are clean! Great job!"
    fi
}

# Function to send email report
send_email_report() {
    local report
    report=$(generate_report)
    
    if [[ -n "$EMAIL_ADDRESS" ]]; then
        echo "$report" | mail -s "Whitespace Maintenance Report - $(date '+%Y-%m-%d')" "$EMAIL_ADDRESS"
        log_message "Email report sent to $EMAIL_ADDRESS"
    fi
}

# Main function
main() {
    local quiet=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dirs)
                REPO_DIRS="$2"
                shift 2
                ;;
            -f|--fix)
                AUTO_FIX=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -e|--email)
                EMAIL_ADDRESS="$2"
                EMAIL_REPORT=true
                shift 2
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -*)
                print_status "$RED" "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                print_status "$RED" "Unexpected argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    if [[ "$quiet" != "true" ]]; then
        print_status "$BLUE" "🔍 Starting whitespace maintenance..."
        print_status "$BLUE" "Directories: $REPO_DIRS"
        print_status "$BLUE" "Auto-fix: $AUTO_FIX"
        print_status "$BLUE" "Log file: $LOG_FILE"
    fi
    
    log_message "Starting whitespace maintenance"
    log_message "Directories: $REPO_DIRS"
    log_message "Auto-fix: $AUTO_FIX"
    
    local total_repos=0
    local repos_with_issues=0
    
    # Process each directory
    IFS=',' read -ra DIR_ARRAY <<< "$REPO_DIRS"
    for dir in "${DIR_ARRAY[@]}"; do
        dir=$(echo "$dir" | xargs) # Trim whitespace
        
        if [[ ! -d "$dir" ]]; then
            log_message "Warning: Directory $dir does not exist"
            continue
        fi
        
        # Find all git repositories in the directory
        while IFS= read -r -d '' repo; do
            ((total_repos++))
            if ! check_repository "$repo"; then
                ((repos_with_issues++))
            fi
        done < <(find "$dir" -name ".git" -type d -print0)
    done
    
    log_message "Maintenance complete. Checked $total_repos repositories, $repos_with_issues had issues"
    
    # Generate and send report if requested
    if [[ "$EMAIL_REPORT" == "true" ]]; then
        send_email_report
    fi
    
    if [[ "$quiet" != "true" ]]; then
        print_status "$GREEN" "✅ Maintenance complete!"
        print_status "$BLUE" "Checked $total_repos repositories"
        if [[ "$repos_with_issues" -gt 0 ]]; then
            print_status "$YELLOW" "Found issues in $repos_with_issues repositories"
        else
            print_status "$GREEN" "All repositories are clean!"
        fi
    fi
    
    # Exit with error code if issues were found and not fixed
    if [[ "$repos_with_issues" -gt 0 && "$AUTO_FIX" != "true" ]]; then
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
