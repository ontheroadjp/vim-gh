" GitHub label definitions
let g:gh_labels = [
      \ {'name': 'consideration',        'color': '0e8a16', 'description': 'Before tasks'},
      \ {'name': 'todo',        'color': '0e8a16', 'description': 'Tasks to do'},
      \ {'name': 'bug',         'color': 'd73a4a', 'description': 'Bug reports'},
      \ {'name': 'enhancement','color': 'a2eeef', 'description': 'New feature requests'},
      \ {'name': 'spec',         'color': '#5f4b34', 'description': 'Bug reports'},
      \ {'name': 'docs',        'color': '0e8a16', 'description': 'Documentation updates'},
      \ {'name': 'test',        'color': '5319e7', 'description': 'Testing related'}
      \ ]

" Optional: Confirm on :w for *.todo, *.bug
augroup gh_issue_confirm
  autocmd!
  autocmd BufWritePre *.consideration,*.todo,*.bug,*.enhancement,*.spec,*.docs,*.test call gh#ConfirmCreateGHIssue()
augroup END

" key bindings
nnoremap <leader>ghi :call gh#SendBufferToGH()<CR>
nnoremap <silent> <leader>ghl :call gh#ListAndOpenGitHubIssues()<CR>

