" vim-practice/test.vim — headless test suite
" Run with:  nvim --headless -u NONE -S test.vim; echo "exit: $?"
" Exit code 0 = all tests pass, 1 = failures

source plugin/vim-practice.vim

" ─── tiny test framework ─────────────────────────────────────────────────────

let s:pass = 0
let s:fail = 0

function! s:ok(label, got, expected) abort
  if a:got ==# a:expected
    let s:pass += 1
    echo '  PASS  ' . a:label
  else
    let s:fail += 1
    echohl ErrorMsg
    echo '  FAIL  ' . a:label
    echo '        expected: ' . string(a:expected)
    echo '        got:      ' . string(a:got)
    echohl None
  endif
endfunction

function! s:ok_true(label, expr) abort
  call s:ok(a:label, a:expr, 1)
endfunction

function! s:done() abort
  echo ''
  echo printf('  %d passed, %d failed', s:pass, s:fail)
  echo ''
  call feedkeys(s:fail > 0 ? ":cquit\<CR>" : ":qall!\<CR>")
endfunction

" ─── tests ───────────────────────────────────────────────────────────────────

echo ''
echohl Title | echo '  vim-practice test suite' | echohl None
echo '  ' . repeat('─', 40)
echo ''

" g:vp.challenges() ─────────────────────────────────────────────────────────────

let s:all = g:vp.challenges()

call s:ok_true('challenges() returns a non-empty list',
      \ len(s:all) > 0)

call s:ok_true('challenges() returns only directories',
      \ empty(filter(copy(s:all), '!isdirectory(v:val)')))

call s:ok_true('challenges() list is sorted',
      \ s:all ==# sort(copy(s:all)))

call s:ok_true('challenges() count is 20',
      \ len(s:all) == 20)

" g:vp.meta() ───────────────────────────────────────────────────────────────────

let s:dir1 = s:all[0]

call s:ok_true('meta() reads DESCRIPTION',
      \ !empty(g:vp.meta(s:dir1, 'DESCRIPTION')))

call s:ok_true('meta() reads OPTIMAL as non-empty string',
      \ !empty(g:vp.meta(s:dir1, 'OPTIMAL')))

call s:ok_true('meta() OPTIMAL is a positive integer',
      \ str2nr(g:vp.meta(s:dir1, 'OPTIMAL')) > 0)

call s:ok('meta() returns empty string for missing key',
      \ g:vp.meta(s:dir1, 'NONEXISTENT'), '')

call s:ok('meta() returns empty string for missing file',
      \ g:vp.meta('/no/such/dir', 'DESCRIPTION'), '')

" Every challenge has required files ──────────────────────────────────────────

let s:missing = []
for s:dir in s:all
  for s:f in ['start.txt', 'target.txt', 'info.txt']
    if !filereadable(s:dir . '/' . s:f)
      call add(s:missing, fnamemodify(s:dir, ':t') . '/' . s:f)
    endif
  endfor
endfor

call s:ok('all challenges have start.txt, target.txt, info.txt',
      \ s:missing, [])

" g:vp.compare() ────────────────────────────────────────────────────────────────

call s:ok_true('compare() returns 1 for identical lists',
      \ g:vp.compare(['a', 'b'], ['a', 'b']))

call s:ok_true('compare() returns 0 for different lists',
      \ !g:vp.compare(['a', 'b'], ['a', 'c']))

call s:ok_true('compare() returns 0 for different lengths',
      \ !g:vp.compare(['a'], ['a', 'b']))

call s:ok_true('compare() is case-sensitive',
      \ !g:vp.compare(['Hello'], ['hello']))

" g:vp.work_path() ──────────────────────────────────────────────────────────────

let s:wp = g:vp.work_path(s:all[0])

call s:ok_true('work_path() includes challenge name',
      \ s:wp =~# fnamemodify(s:all[0], ':t'))

call s:ok_true('work_path() ends in .txt',
      \ s:wp =~# '\.txt$')

call s:ok_true('work_path() is under .tmp/',
      \ s:wp =~# '/\.tmp/')

call s:ok_true('work_path() differs per challenge',
      \ g:vp.work_path(s:all[0]) !=# g:vp.work_path(s:all[1]))

" start.txt ≠ target.txt (each challenge actually requires a change) ───────────

let s:trivial = []
for s:dir in s:all
  let s:start  = readfile(s:dir . '/start.txt')
  let s:target = readfile(s:dir . '/target.txt')
  if s:start ==# s:target
    call add(s:trivial, fnamemodify(s:dir, ':t'))
  endif
endfor

call s:ok('no challenge has identical start and target',
      \ s:trivial, [])

" OPTIMAL values are all positive integers ────────────────────────────────────

let s:bad_optimal = []
for s:dir in s:all
  let s:opt = str2nr(g:vp.meta(s:dir, 'OPTIMAL'))
  if s:opt <= 0
    call add(s:bad_optimal, fnamemodify(s:dir, ':t'))
  endif
endfor

call s:ok('all challenges have OPTIMAL > 0',
      \ s:bad_optimal, [])

" s:inputlist_pick entry format — numbers parse correctly ────────────────────

let s:all = g:vp.challenges()
let s:entries = []
let s:i = 1
for s:dir in s:all
  call add(s:entries, printf('%2d  %-50s %s keys', s:i,
        \ g:vp.meta(s:dir, 'DESCRIPTION'), g:vp.meta(s:dir, 'OPTIMAL')))
  let s:i += 1
endfor

call s:ok_true('pick entries count matches challenges',
      \ len(s:entries) == len(s:all))

call s:ok_true('first entry parses to challenge 1',
      \ str2nr(matchstr(s:entries[0], '^\s*\zs\d\+')) == 1)

call s:ok_true('last entry parses to correct challenge number',
      \ str2nr(matchstr(s:entries[-1], '^\s*\zs\d\+')) == len(s:all))

let s:idx_ok = 1
for s:j in range(len(s:entries))
  if str2nr(matchstr(s:entries[s:j], '^\s*\zs\d\+')) != s:j + 1
    let s:idx_ok = 0
  endif
endfor
call s:ok_true('each entry starts with its 1-based index', s:idx_ok)

" VimChallenge sets t: vars inside the new tab (regression: was set before tabnew) ──

let s:tab_before = tabpagenr()
VimChallenge 1
call s:ok_true('VimChallenge opens a new tab',
      \ tabpagenr() != s:tab_before)
call s:ok_true('t:vp_name exists in new tab after VimChallenge',
      \ exists('t:vp_name'))
call s:ok_true('t:vp_dir exists in new tab after VimChallenge',
      \ exists('t:vp_dir'))
call s:ok_true('t:vp_target exists in new tab after VimChallenge',
      \ exists('t:vp_target'))
call s:ok_true('t:vp_optimal exists in new tab after VimChallenge',
      \ exists('t:vp_optimal'))
tabclose

" Buffer picker — buffer properties ──────────────────────────────────────────
" fzf#run is not available under -u NONE, so VimList always uses the buffer picker

VimList

call s:ok('picker: buftype is nofile',
      \ &buftype, 'nofile')
call s:ok_true('picker: nomodifiable',
      \ !&modifiable)
call s:ok_true('picker: cursorline enabled',
      \ &cursorline)
call s:ok_true('picker: line count equals challenge count',
      \ line('$') ==# len(g:vp.challenges()))
call s:ok_true('picker: line 1 represents challenge 1',
      \ str2nr(matchstr(getline(1), '^\s*\zs\d\+')) ==# 1)
call s:ok_true('picker: last line represents last challenge',
      \ str2nr(matchstr(getline('$'), '^\s*\zs\d\+')) ==# len(g:vp.challenges()))

" Buffer picker — selection loads the correct challenge ───────────────────────

normal! 5G
let s:pick_tab_before = tabpagenr()
call feedkeys("\<CR>", 'xt')

call s:ok_true('picker: opens a new tab on selection',
      \ tabpagenr() !=# s:pick_tab_before)
call s:ok_true('picker: t:vp_name set after selection',
      \ exists('t:vp_name'))
call s:ok_true('picker: correct challenge loaded (challenge 5)',
      \ t:vp_name =~# '^05_')
tabclose

" ─────────────────────────────────────────────────────────────────────────────

call s:done()
