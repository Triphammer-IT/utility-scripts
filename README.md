# Utility Scripts

A collection of utility scripts for repository management and automation.

## Scripts

### whitespace-linter.sh

A comprehensive whitespace linter that detects and can fix trailing whitespace and whitespace-only lines in files.

#### Features

- **Trailing Whitespace Detection**: Finds spaces and tabs at the end of lines
- **Whitespace-Only Line Detection**: Identifies lines that contain only spaces/tabs (not empty lines)
- **Automatic Fixing**: Can automatically remove trailing whitespace and convert whitespace-only lines to empty lines
- **Recursive Directory Scanning**: Can process entire directory trees
- **File Type Filtering**: Support for checking only specific file extensions
- **Pattern Ignoring**: Skip files matching specified patterns
- **Visual Feedback**: Shows whitespace characters as visible symbols (· for spaces, → for tabs)
- **Comprehensive Reporting**: Detailed summary with issue counts and file statistics

#### Usage

```bash
# Check current directory
./whitespace-linter.sh

# Check specific file
./whitespace-linter.sh file.txt

# Recursively check directory
./whitespace-linter.sh -r /path/to/code

# Fix all issues automatically
./whitespace-linter.sh -f -r .

# Check only specific file types
./whitespace-linter.sh -e sh,py,js -r .

# Ignore certain file patterns
./whitespace-linter.sh -i '*.log,*.tmp' -r .

# Show detailed output
./whitespace-linter.sh -v file.txt

# Quiet mode (summary only)
./whitespace-linter.sh -q -r .
```

#### Examples

```bash
# Basic usage - check current directory
./whitespace-linter.sh

# Fix all whitespace issues in your codebase
./whitespace-linter.sh -f -r /path/to/project

# Check only shell and Python files
./whitespace-linter.sh -e sh,py -r .

# Verbose output showing exactly what whitespace was found
./whitespace-linter.sh -v example.txt
```

#### Output

The linter provides:
1. **Per-file Results**: Shows issues found in each file with line numbers
2. **Visual Whitespace**: Displays spaces as `·` and tabs as `→` for easy identification
3. **Summary Report**: Total counts of files processed, issues found, and breakdown by issue type
4. **Fix Suggestions**: Tips on using the automatic fix feature

#### Safety Features

- Creates backups (`.bak` files) before making changes in fix mode
- Non-destructive by default (only reports issues unless `-f` is used)
- Skips binary files automatically
- Configurable file type and pattern filtering

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
