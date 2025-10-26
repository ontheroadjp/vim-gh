" ================================================
" Gemini + GitHub CLI Integration for Vim
" ================================================
" Features:
" 1. Visual selection translation to English using Gemini CLI
" 2. YAML frontmatter parsing for title, label, assignee, milestone
" 3. Buffer auto-send to GitHub Issue via gh CLI
" 4. Ignores Gemini/Node warnings and stderr logs
" ================================================

" ---- YAML frontmatter parsing (fixed version) ----
function! gh#ParseYAMLFrontmatter()
  " Find YAML frontmatter boundaries (--- ... ---
  let l:start = search('^---$', 'n')
  if l:start == 0
    return ['', '', '', '']
  endif
  let l:end = search('^---$', 'n', l:start + 1)
  if l:end == 0
    return ['', '', '', '']
  endif

  " Read lines within YAML block
  let l:lines = getline(l:start + 1, l:end - 1)
  let l:title = ''
  let l:label = ''
  let l:assignee = ''
  let l:milestone = ''

  " Parse each line individually
  for l:line in l:lines
    if l:line =~? '^title:\s*'
      let l:title = substitute(l:line, '^title:\s*', '', '')
    elseif l:line =~? '^label:\s*'
      let l:label = substitute(l:line, '^label:\s*', '', '')
    elseif l:line =~? '^assignee:\s*'
      let l:assignee = substitute(l:line, '^assignee:\s*', '', '')
    elseif l:line =~? '^milestone:\s*'
      let l:milestone = substitute(l:line, '^milestone:\s*', '', '')
    endif
  endfor

  return [l:title, l:label, l:assignee, l:milestone]
endfunction

" =========================================
" Ensure label exists on GitHub
" =========================================
function! gh#EnsureLabelExists(label)
  if a:label == ''
    return
  endif

  " Get existing labels from GitHub
  let l:existing = systemlist('gh label list --json name | jq -r ".[].name"')
  if index(l:existing, a:label) != -1
    return
  endif

  " Search in Vimscript label definitions
  let l:found = 0
  for l:item in g:gh_labels
    if l:item.name ==# a:label
      let l:cmd = 'gh label create ' . shellescape(l:item.name) . \
                  \ ' --color ' . shellescape(l:item.color) . \
                  \ ' --description ' . shellescape(l:item.description)
      call system(l:cmd)
      let l:found = 1
      break
    endif
  endfor

  if !l:found
    echoerr "❌ Label '" . a:label . "' is not defined in the script"
    throw "Label not defined"
  endif
endfunction

" ===========================================================================
" Function: SendBufferToGH
" ===========================================================================
function! gh#SendBufferToGH()
  let l:lines = getline(1, '$')

  " YAML front matter
  let l:start = index(l:lines, '---')
  if l:start == -1
    echoerr "YAML front matter not found"
    return
  endif
  let l:end = index(l:lines[l:start+1:], '---')
  if l:end == -1
    echoerr "YAML front matter end not found"
    return
  endif
  let l:end = l:start + l:end + 1

  " Parse YAML fields
  let l:title = ''
  let l:label = ''
  let l:assignee = ''
  let l:milestone = ''

  for l:line in l:lines[l:start+1 : l:end-1]
    if l:line =~ '^title:'
      let l:title = trim(substitute(l:line, '^title:\s*', '', ''))
    elseif l:line =~ '^label:'
      let l:label = trim(substitute(l:line, '^label:\s*', '', ''))
    elseif l:line =~ '^assignee:'
      let l:assignee = trim(substitute(l:line, '^assignee:\s*', '', ''))
    elseif l:line =~ '^milestone:'
      let l:milestone = trim(substitute(l:line, '^milestone:\s*', '', ''))
    endif
  endfor

  " Ensure label exists or create it
  call gh#EnsureLabelExists(l:label)

  " Body
  let l:body_lines = l:lines[l:end+1 :]
  let l:tmpfile = tempname() . '.md'
  call writefile(l:body_lines, l:tmpfile)

  " Build gh command
  let l:cmd = 'gh issue create'
  if l:title !=# ''       | let l:cmd .= ' --title ' . shellescape(l:title)       | endif
  if l:label !=# ''       | let l:cmd .= ' --label ' . shellescape(l:label)       | endif
  if l:assignee !=# ''    | let l:cmd .= ' --assignee ' . shellescape(l:assignee) | endif
  if l:milestone !=# ''   | let l:cmd .= ' --milestone ' . shellescape(l:milestone) | endif
  let l:cmd .= ' --body-file ' . shellescape(l:tmpfile)

  " Execute
  let l:output = system(l:cmd)

  if v:shell_error == 0
    echo "✅ Issue created successfully!"
    let l:url = matchstr(l:output, 'https://github\.com/\S+')
    if l:url != ''
      echo "🌐 " . l:url
    endif

    " Delete buffer
    call delete(expand('%'))
    bdelete!
    echo "🗑️  Local file deleted after successful issue creation."

    " Delete temp file
    call delete(l:tmpfile)
    return 1
  else
      echoerr "❌ Failed to create issue."
      echohl WarningMsg
      echom "Command: " . l:cmd
      echom "Output: " . l:output
      echohl None
      return 0
  endif
endfunction

" =========================================
" Optional: Confirm on :w for *.todo, *.bug
" =========================================
function! gh#ConfirmCreateGHIssue()
  let l:choice = input("💡 Create GitHub Issue? (y/N): ")
  if tolower(l:choice) ==# 'y'
    let l:success = gh#SendBufferToGH()
    if l:success
      execute "bwipeout!"
    endif
  endif
endfunction

" ===========================================================================
" Function: ListAndOpenGitHubIssues
" ===========================================================================
let g:gh_issues_prev_buf = 0  " Store previous buffer globally

function! gh#ListAndOpenGitHubIssues()
  " Save current buffer number
  let g:gh_issues_prev_buf = bufnr('%')

  " Temporary file
  let l:tmpfile = tempname()

  " Fetch issues as TSV
  let l:cmd = "gh issue list --state open --limit 100 --json number,title,assignees,labels,createdAt --jq '.[] | [(.number|tostring), .title, (.assignees|map(.login)|join(", ")), (.labels|map(.name)|join(", ")), .createdAt] | @tsv' > " . shellescape(l:tmpfile)
  call system(l:cmd)

  " Read TSV lines
  let l:lines = readfile(l:tmpfile)
  call delete(l:tmpfile)  " Cleanup temporary file

  if empty(l:lines)
    echo "No open issues found."
    return
  endif

  " Split TSV into array of arrays, ensure 5 columns
  let l:rows = []
  for line in l:lines
    if line != ''
      let l:cols = split(line, "\t")
      while len(l:cols) < 5
        call add(l:cols, '')
      endwhile
      call add(l:rows, l:cols)
    endif
  endfor

  " Determine max width for each column safely
  let l:widths = []
  for i in range(5)
    let l:maxlen = 0
    for row in l:rows
      if i < len(row)
        let l:maxlen = max([l:maxlen, strlen(row[i])])
      endif
    endfor
    call add(l:widths, l:maxlen)
  endfor

  " Build formatted lines with header
  let l:formatted = []
  let l:headers = ['Number','Title','Assignees','Labels','CreatedAt']
  let l:line = ''
  for idx in range(5)
    let l:line .= printf('%-*s', l:widths[idx]+2, l:headers[idx])
  endfor
  call add(l:formatted, l:line)

  " Add separator
  let l:sep = ''
  for idx in range(5)
    let l:sep .= repeat('-', l:widths[idx]+2)
  endfor
  call add(l:formatted, l:sep)

  " Add issue rows
  for row in l:rows
    let l:line = ''
    for idx in range(5)
      let l:line .= printf('%-*s', l:widths[idx]+2, row[idx])
    endfor
    call add(l:formatted, l:line)
  endfor

  " Open new buffer and display
  enew
  %delete _
  call setline(1, l:formatted)
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal nobuflisted
  setlocal readonly
  setlocal nonumber
  setlocal norelativenumber

  " Map Enter to open issue in browser
  nnoremap <buffer> <CR> :call gh#OpenSelectedIssue()<CR>
endfunction

" ===========================================================================
" Function: OpenSelectedIssue
" ===========================================================================
function! gh#OpenSelectedIssue()
  let l:line = getline('.')
  let l:num = matchstr(l:line, '^\d\+')
  if l:num == ''
    echo "No issue number found on this line."
    return
  endif

  " Open issue in web browser
  call system('gh issue view ' . l:num . ' --web')
  echo "Opening issue #" . l:num

  " Return to previous buffer
  if g:gh_issues_prev_buf > 0 && buflisted(g:gh_issues_prev_buf)
    execute 'buffer' g:gh_issues_prev_buf
  endif
endfunction
