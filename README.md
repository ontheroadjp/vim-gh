# vim-gh.vim

A Vim plugin for creating GitHub issues from the comfort of your favorite editor.

## Features

- Create GitHub issues from the current buffer.
- Parse YAML frontmatter for issue metadata (title, labels, assignees, milestone).
- List open issues and open them in your browser.

## Installation

Use your favorite plugin manager. For example, with vim-plug:

```vim
Plug 'path/to/your/dotfiles/tools/gh-issue-creator'
```

## Usage

- `:call gh#SendBufferToGH()` - Create an issue from the current buffer.
- `:call gh#ListAndOpenGitHubIssues()` - List open issues.
- `<leader>ghi` - Shortcut to create an issue.
- `<leader>ghl` - Shortcut to list issues.
