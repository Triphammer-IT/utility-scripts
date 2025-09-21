# Utility Scripts

A collection of utility scripts for repository management and automation.

## Scripts

### check-repos.sh

A comprehensive repository status checker and batch manager that recursively scans directories for git repositories and checks for uncommitted changes and unpushed commits.

#### Features

- **Recursive Scanning**: Automatically finds all git repositories in a directory tree
- **Status Detection**: Identifies repositories with:
  - Uncommitted changes (modified, staged, or untracked files)
  - Unpushed commits (commits ahead of origin)
  - Both uncommitted changes and unpushed commits
- **Batch Operations**: Offers to commit and push changes for:
  - All repositories at once
  - Selectively chosen repositories
- **Detailed Reporting**: Optional detailed status showing current branch, file changes, and commit history
- **Color-coded Output**: Easy-to-read status indicators

#### Usage

```bash
# Check current directory
./check-repos.sh

# Check specific directory
./check-repos.sh /path/to/repos

# Show detailed status for each repository
./check-repos.sh -d

# Quiet mode (minimal output)
./check-repos.sh -q

# Show help
./check-repos.sh -h
```

#### Examples

```bash
# Basic usage - scan current directory
./check-repos.sh

# Scan your entire git-repos directory
./check-repos.sh /Users/john/code/git-repos/mine

# Get detailed information about each repo with changes
./check-repos.sh -d /path/to/repos
```

#### Output

The script provides:
1. **Summary Report**: Lists all repositories with changes, categorized by type
2. **Batch Operations Menu**: Options to commit and push changes
3. **Progress Updates**: Real-time feedback during operations

#### Safety Features

- Non-destructive by default (only shows status unless you choose to commit/push)
- Confirmation prompts for batch operations
- Detailed logging of all operations
- Error handling for repositories without remotes

## Installation

1. Clone this repository
2. Make scripts executable: `chmod +x *.sh`
3. Run from any directory to check repositories

## Requirements

- `git` command line tool
- `bash` shell
- Standard Unix utilities (`basename`, `realpath`, etc.)

## Contributing

Feel free to add more utility scripts to this collection. Please ensure:
- Scripts are well-documented
- Shellcheck passes without errors
- Scripts follow the established patterns for error handling and user interaction
