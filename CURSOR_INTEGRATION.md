# Cursor/VS Code Integration for Whitespace Linter

This guide shows how to integrate the whitespace linter with Cursor (VS Code-based editor) for silent, automatic whitespace checking that only alerts on errors.

## Overview

The integration uses VS Code's task system and file watcher to:
- Run the whitespace linter automatically on file changes
- Show issues in the Problems panel
- Operate silently in the background
- Only alert when actual whitespace issues are found

## Setup

### 1. Create VS Code Tasks Configuration

Create `.vscode/tasks.json` in your project root:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Whitespace Lint",
            "type": "shell",
            "command": "${workspaceFolder}/utility-scripts/whitespace-linter.sh",
            "args": ["-v", "${file}"],
            "group": "build",
            "presentation": {
                "echo": false,
                "reveal": "silent",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": false,
                "clear": false
            },
            "problemMatcher": {
                "owner": "whitespace-linter",
                "fileLocation": "absolute",
                "pattern": {
                    "regexp": "^\\s+Line (\\d+): (trailing whitespace|whitespace-only line)$",
                    "file": 1,
                    "line": 1,
                    "message": 2
                },
                "background": {
                    "activeOnStart": false,
                    "beginsPattern": "^🔍 Starting whitespace lint check\\.\\.\\.$",
                    "endsPattern": "^=== WHITESPACE LINT SUMMARY ===$"
                }
            },
            "runOptions": {
                "runOn": "folderOpen"
            }
        },
        {
            "label": "Whitespace Lint (Fix)",
            "type": "shell",
            "command": "${workspaceFolder}/utility-scripts/whitespace-linter.sh",
            "args": ["-f", "${file}"],
            "group": "build",
            "presentation": {
                "echo": false,
                "reveal": "silent",
                "focus": false,
                "panel": "shared",
                "showReuseMessage": false,
                "clear": false
            }
        }
    ]
}
```

### 2. Create VS Code Settings

Add to your workspace `.vscode/settings.json` or global `settings.json`:

```json
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/.venv/**": true,
        "**/__pycache__/**": true,
        "**/build/**": true,
        "**/dist/**": true
    },
    "files.autoSave": "onFocusChange",
    "whitespace-linter.enabled": true,
    "whitespace-linter.autoFix": false,
    "whitespace-linter.fileTypes": [
        "sh", "py", "js", "ts", "html", "css", "md", "txt",
        "yml", "yaml", "json", "xml", "go", "rs", "java", "cpp", "c"
    ]
}
```

### 3. Create Keyboard Shortcuts

Add to your `keybindings.json`:

```json
[
    {
        "key": "ctrl+shift+w",
        "command": "workbench.action.tasks.runTask",
        "args": "Whitespace Lint"
    },
    {
        "key": "ctrl+shift+alt+w",
        "command": "workbench.action.tasks.runTask",
        "args": "Whitespace Lint (Fix)"
    }
]
```

## Advanced Integration

### 1. Custom Extension (Optional)

For more advanced integration, create a simple VS Code extension:

**package.json:**
```json
{
    "name": "whitespace-linter",
    "displayName": "Whitespace Linter",
    "description": "Integrates custom whitespace linter with VS Code",
    "version": "1.0.0",
    "engines": {
        "vscode": "^1.74.0"
    },
    "categories": ["Linters"],
    "activationEvents": [
        "onLanguage:shellscript",
        "onLanguage:python",
        "onLanguage:javascript",
        "onLanguage:typescript"
    ],
    "main": "./out/extension.js",
    "contributes": {
        "commands": [
            {
                "command": "whitespace-linter.check",
                "title": "Check Whitespace"
            },
            {
                "command": "whitespace-linter.fix",
                "title": "Fix Whitespace"
            }
        ],
        "keybindings": [
            {
                "command": "whitespace-linter.check",
                "key": "ctrl+shift+w",
                "when": "editorTextFocus"
            },
            {
                "command": "whitespace-linter.fix",
                "key": "ctrl+shift+alt+w",
                "when": "editorTextFocus"
            }
        ]
    }
}
```

**extension.js:**
```javascript
const vscode = require('vscode');
const { exec } = require('child_process');
const path = require('path');

function activate(context) {
    const linterPath = path.join(context.extensionPath, '..', 'utility-scripts', 'whitespace-linter.sh');

    const checkWhitespace = vscode.commands.registerCommand('whitespace-linter.check', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) return;

        const filePath = editor.document.fileName;
        exec(`"${linterPath}" -v "${filePath}"`, (error, stdout, stderr) => {
            if (error) {
                // Parse output and show in Problems panel
                const diagnostics = parseLinterOutput(stdout, filePath);
                const collection = vscode.languages.createDiagnosticCollection('whitespace-linter');
                collection.set(vscode.Uri.file(filePath), diagnostics);
            }
        });
    });

    const fixWhitespace = vscode.commands.registerCommand('whitespace-linter.fix', () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) return;

        const filePath = editor.document.fileName;
        exec(`"${linterPath}" -f "${filePath}"`, (error, stdout, stderr) => {
            if (!error) {
                vscode.window.showInformationMessage('Whitespace issues fixed!');
                // Reload the document
                vscode.workspace.openTextDocument(filePath).then(doc => {
                    vscode.window.showTextDocument(doc);
                });
            }
        });
    });

    context.subscriptions.push(checkWhitespace, fixWhitespace);
}

function parseLinterOutput(output, filePath) {
    const diagnostics = [];
    const lines = output.split('\n');

    for (const line of lines) {
        const match = line.match(/^\s+Line (\d+): (trailing whitespace|whitespace-only line)$/);
        if (match) {
            const lineNum = parseInt(match[1]) - 1;
            const message = match[2];

            diagnostics.push({
                range: new vscode.Range(lineNum, 0, lineNum, 0),
                message: message,
                severity: vscode.DiagnosticSeverity.Warning,
                source: 'whitespace-linter'
            });
        }
    }

    return diagnostics;
}

function deactivate() {}

module.exports = {
    activate,
    deactivate
};
```

### 2. File Watcher Integration

For automatic checking on file changes, add to your extension:

```javascript
// In extension.js activate function
const fileWatcher = vscode.workspace.createFileSystemWatcher('**/*');
fileWatcher.onDidChange(uri => {
    if (shouldCheckFile(uri.fsPath)) {
        checkFileWhitespace(uri.fsPath);
    }
});

function shouldCheckFile(filePath) {
    const ext = path.extname(filePath).slice(1);
    const allowedExts = ['sh', 'py', 'js', 'ts', 'html', 'css', 'md', 'txt', 'yml', 'yaml', 'json', 'xml'];
    return allowedExts.includes(ext);
}
```

## Usage

### Manual Checking
- **Keyboard shortcut**: `Ctrl+Shift+W` to check current file
- **Command palette**: "Whitespace Lint" command
- **Problems panel**: View all whitespace issues

### Auto-fixing
- **Keyboard shortcut**: `Ctrl+Shift+Alt+W` to fix current file
- **Command palette**: "Whitespace Lint (Fix)" command

### Automatic Operation
- Issues appear in Problems panel automatically
- No popup notifications unless there are errors
- Silent background operation

## Configuration Options

### Workspace Settings
```json
{
    "whitespace-linter.enabled": true,
    "whitespace-linter.autoFix": false,
    "whitespace-linter.fileTypes": ["sh", "py", "js", "ts"],
    "whitespace-linter.ignorePatterns": ["*.log", "*.tmp"],
    "whitespace-linter.checkTrailing": true,
    "whitespace-linter.checkWhitespaceOnly": true
}
```

### Global Settings
Add to your global `settings.json` for all projects:
```json
{
    "whitespace-linter.globalEnabled": true,
    "whitespace-linter.defaultFileTypes": [
        "sh", "py", "js", "ts", "html", "css", "md", "txt",
        "yml", "yaml", "json", "xml", "go", "rs", "java", "cpp", "c"
    ]
}
```

## Troubleshooting

### Common Issues

1. **Linter not found**
   - Ensure `whitespace-linter.sh` is executable
   - Check path in tasks.json is correct
   - Verify file permissions

2. **Problems not showing**
   - Check problemMatcher regex in tasks.json
   - Verify linter output format
   - Check VS Code Problems panel is open

3. **Performance issues**
   - Limit file types in settings
   - Use file watcher exclusions
   - Consider debouncing file changes

### Debug Mode
Enable debug output by modifying the task:
```json
{
    "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "new"
    }
}
```

## Benefits

- **Silent operation**: Only alerts when issues are found
- **Real-time feedback**: Issues appear in Problems panel
- **Non-intrusive**: No popup notifications
- **Integrated**: Uses VS Code's built-in diagnostic system
- **Configurable**: Customizable file types and behavior
- **Keyboard shortcuts**: Quick access to check/fix functions

This integration provides a seamless experience where whitespace issues are caught automatically without interrupting your workflow.
