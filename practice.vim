" vim-practice/practice.vim
" Open with:  vim -S practice.vim
"       or:   :source path/to/practice.vim

if exists('g:vim_practice_loaded') | finish | endif
let g:vim_practice_loaded = 1

let s:root           = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:challenges_dir = s:root . '/challenges'
let s:tmp            = s:root . '/.tmp'

" ─── pure helpers — exposed via g:vp dict so tests can call them ─────────────

let g:vp = {}

function! g:vp.challenges() abort
  return sort(filter(glob(s:challenges_dir . '/*', 1, 1), 'isdirectory(v:val)'))
endfunction

function! g:vp.meta(dir, key) abort
  let info = a:dir . '/info.txt'
  if !filereadable(info) | return '' | endif
  for line in readfile(info)
    if line =~# '^' . a:key . ':'
      return trim(substitute(line, '^' . a:key . ':\s*', '', ''))
    endif
  endfor
  return ''
endfunction

function! g:vp.compare(buf_lines, target_lines) abort
  return a:buf_lines ==# a:target_lines
endfunction

function! g:vp.work_path(challenge_dir) abort
  return s:tmp . '/' . fnamemodify(a:challenge_dir, ':t') . '.txt'
endfunction

" ─── display helpers ─────────────────────────────────────────────────────────

function! s:hl(msg, group) abort
  execute 'echohl ' . a:group | echo a:msg | echohl None
endfunction

" ─── :VimList ────────────────────────────────────────────────────────────────

function! s:list() abort
  let all = g:vp.challenges()
  if empty(all)
    call s:hl('  No challenges found in ' . s:challenges_dir, 'WarningMsg')
    return
  endif
  echo ''
  call s:hl('  Vim Practice — Challenges', 'Title')
  echo '  ' . repeat('─', 58)
  let i = 1
  for dir in all
    let desc = g:vp.meta(dir, 'DESCRIPTION')
    let opt  = g:vp.meta(dir, 'OPTIMAL')
    echo printf('  %2d.  %-46s %s keys', i, desc, opt)
    let i += 1
  endfor
  echo ''
endfunction

" ─── :VimPick ─────────────────────────────────────────────────────────────────

function! s:pick() abort
  let all = g:vp.challenges()
  if empty(all)
    call s:hl('  No challenges found in ' . s:challenges_dir, 'WarningMsg')
    return
  endif

  let entries = []
  let i = 1
  for dir in all
    let desc = g:vp.meta(dir, 'DESCRIPTION')
    let opt  = g:vp.meta(dir, 'OPTIMAL')
    call add(entries, printf('%2d  %-50s %s keys', i, desc, opt))
    let i += 1
  endfor

  if exists('*fzf#run')
    call fzf#run(fzf#wrap('vim-practice', {
          \ 'source':  entries,
          \ 'sink':    function('s:fzf_sink'),
          \ 'options': ['--prompt', 'Challenge> ', '--no-multi',
          \             '--preview-window', 'hidden'],
          \ }))
  else
    call s:inputlist_pick(entries)
  endif
endfunction

function! s:fzf_sink(line) abort
  let n = str2nr(matchstr(a:line, '^\s*\zs\d\+'))
  if n > 0
    call s:load(n)
  endif
endfunction

function! s:inputlist_pick(entries) abort
  let height = min([len(a:entries), 15])
  execute 'botright ' . height . 'split'
  enew
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nonumber norelativenumber nocursorcolumn cursorline
  setlocal statusline=\ Vim\ Practice\ \ \ <CR>\ load\ \ j/k\ navigate\ \ q\ close

  call setline(1, a:entries)
  setlocal nomodifiable readonly
  normal! gg

  let b:vp_entry_count = len(a:entries)

  nnoremap <buffer> <silent> <CR>  :call <SID>picker_select()<CR>
  nnoremap <buffer> <silent> q     :bwipe!<CR>
  nnoremap <buffer> <silent> <Esc> :bwipe!<CR>
endfunction

function! s:picker_select() abort
  let n     = line('.')
  let count = b:vp_entry_count
  bwipe!
  if n >= 1 && n <= count
    call s:load(n)
  endif
endfunction

" ─── :VimChallenge {n} ───────────────────────────────────────────────────────

function! s:load(n) abort
  let all = g:vp.challenges()
  if empty(all)
    call s:hl('  No challenges found in ' . s:challenges_dir, 'ErrorMsg')
    return
  endif

  let idx = a:n - 1
  if idx < 0 || idx >= len(all)
    call s:hl('  No challenge ' . a:n . ' — use :VimList (' . len(all) . ' available)', 'ErrorMsg')
    return
  endif

  let dir    = all[idx]
  let start  = dir . '/start.txt'
  let target = dir . '/target.txt'

  if !filereadable(start)
    call s:hl('  Missing start.txt in ' . dir, 'ErrorMsg') | return
  endif
  if !filereadable(target)
    call s:hl('  Missing target.txt in ' . dir, 'ErrorMsg') | return
  endif

  " Each challenge gets its own working file so tabs don't clobber each other
  call mkdir(s:tmp, 'p')
  let work = g:vp.work_path(dir)
  call writefile(readfile(start), work)

  " Clear register q for this tab's fresh attempt
  call setreg('q', '')

  " Layout: working buffer (top) / target read-only (bottom)
  execute 'tabnew ' . fnameescape(work)

  " Per-tab state lives in the new tab so :VimCheck/:VimReset can access it
  let t:vp_dir     = dir
  let t:vp_target  = target
  let t:vp_optimal = str2nr(g:vp.meta(dir, 'OPTIMAL'))
  let t:vp_name    = fnamemodify(dir, ':t')
  setlocal noswapfile
  execute 'rightbelow split ' . fnameescape(target)
  setlocal readonly nomodifiable noswapfile bufhidden=hide
  setlocal statusline=\ TARGET\ (read\ only)
  wincmd p  " return focus to working buffer

  let &l:statusline = ' ' . t:vp_name
        \ . '  |  optimal: ' . t:vp_optimal . ' keys'
        \ . '  |  qq…q  then  :VimCheck'

  echo ''
  call s:hl('  Loaded: ' . t:vp_name, 'Title')
  call s:hl('  1) qq     start recording', 'Comment')
  call s:hl('  2) <edits>', 'Comment')
  call s:hl('  3) q      stop recording', 'Comment')
  call s:hl('  4) :VimCheck', 'Comment')
  echo ''
endfunction

" ─── :VimCheck ───────────────────────────────────────────────────────────────

function! s:check() abort
  if !exists('t:vp_target')
    call s:hl('  No challenge loaded in this tab — use :VimChallenge {n}', 'WarningMsg')
    return
  endif

  " Guard: must be called from the working buffer, not the read-only target pane
  let work = g:vp.work_path(t:vp_dir)
  if expand('%:p') !=# fnamemodify(work, ':p')
    call s:hl('  Switch to the top (working) buffer first, then run :VimCheck', 'WarningMsg')
    return
  endif

  let keys    = strlen(getreg('q'))
  let correct = g:vp.compare(getline(1, '$'), readfile(t:vp_target))

  echo ''
  call s:hl('  ─── Results: ' . t:vp_name . ' ───', 'Title')
  echo ''

  if correct
    call s:hl('  Correctness : PASS ✓', 'DiffAdd')
  else
    call s:hl('  Correctness : FAIL ✗', 'ErrorMsg')
    echo ''
    echo '  Expected:'
    for line in readfile(t:vp_target) | echo '    ' . line | endfor
    echo '  Got:'
    for line in getline(1, '$')      | echo '    ' . line | endfor
  endif

  echo ''
  echo printf('  Your keys   : %d', keys)
  echo printf('  Optimal     : %d', t:vp_optimal)

  if keys == 0
    call s:hl('  ⚠  register q is empty — did you record with qq … q?', 'WarningMsg')
  elseif keys <= t:vp_optimal
    call s:hl('  Rating      : OPTIMAL OR BETTER ✓', 'DiffAdd')
  elseif keys * 2 <= t:vp_optimal * 3
    call s:hl('  Rating      : GOOD', 'WarningMsg')
  else
    call s:hl('  Rating      : NEEDS WORK', 'ErrorMsg')
  endif

  echo ''
  echo '  Keys typed  : ' . getreg('q')
  echo ''

  let ans = input('  Show solutions? [y/N] ')
  if ans =~? '^y'
    echo ''
    for line in readfile(t:vp_dir . '/info.txt')
      if line =~# '^SOLUTION\|^NOTE'
        call s:hl('  ' . line, 'Comment')
      endif
    endfor
    echo ''
  endif
endfunction

" ─── :VimReset ───────────────────────────────────────────────────────────────

function! s:reset() abort
  if !exists('t:vp_dir')
    call s:hl('  No challenge loaded in this tab', 'WarningMsg') | return
  endif
  let work = g:vp.work_path(t:vp_dir)
  if expand('%:p') !=# fnamemodify(work, ':p')
    call s:hl('  Switch to the working buffer first', 'WarningMsg') | return
  endif
  call writefile(readfile(t:vp_dir . '/start.txt'), work)
  call setreg('q', '')
  edit!
  call s:hl('  Reset to start state. Register q cleared.', 'Comment')
endfunction

" ─── keymaps ─────────────────────────────────────────────────────────────────

nnoremap <Space>v  :VimChallenge<Space>
nnoremap <Space>vp :VimPick<CR>
nnoremap <Space>vc :VimCheck<CR>
nnoremap <Space>vl :VimList<CR>
nnoremap <Space>vr :VimReset<CR>

" ─── commands ────────────────────────────────────────────────────────────────

command!          VimList      call s:list()
command!          VimPick      call s:pick()
command! -nargs=1 VimChallenge call s:load(<args>)
command!          VimCheck     call s:check()
command!          VimReset     call s:reset()

" Show list on load
call s:list()
call s:hl('  :VimPick   :VimChallenge {n}   :VimList   :VimCheck   :VimReset', 'Comment')
echo ''
