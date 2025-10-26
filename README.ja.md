# vim-gh.vim

GitHub issue を閲覧・作成・編集するための Vim プラグイン

## 機能

- 現在のバッファから GitHub issue を作成
- Github issue のメタデータ (タイトル、ラベル、担当者、マイルストーン) のために YAML のフロントマターを解析します
- 開いている Github issue をリストアップし、ブラウザで開く

## インストール

お好きなプラグインマネージャーを使ってください。例えばvim-plugを使います：

```vim
Plug 'path/to/your/dotfiles/toolss/gh-issue-creator'
```

## 使い方

以下の YAML フロントマターを追加してください
``todo`` ラベルを付与、自分に割り当てるサンプルです

```yaml
---
title: "Todo: [short description]"
label: todo
assignee: @me
milestone:
---
```

### コマンド & キーバインド

- `:call gh#SendBufferToGH()` - 現在のバッファから Github issue を作成します。
- `:call gh#ListAndOpenGitHubIssues()` - 開いている Github issue を一覧表示します。
- `<leader>ghi` - Github issue を作成するショートカット。
- `<leader>ghl` - Github issue を一覧表示するショートカット。

