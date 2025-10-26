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

Add the following YAML front matter
Sample of giving a ``todo`` label and assigning it to yourself.

```yaml
---title: "Todo: [short description]" title: "Todo: [short description]
title: "Todo: [short description]"
label: todo
assignee: @me
milestone: ``yaml
--- title: "Todo: [short description
````

### command & key bindings

- `:call gh#SendBufferToGH()` - creates a Github issue from the current buffer.
- `:call gh#ListAndOpenGitHubIssues()` - lists open Github issues.
- `<leader>ghi` - shortcut for creating a Github issue.
- `<leader>ghl` - shortcut to list Github issues.

