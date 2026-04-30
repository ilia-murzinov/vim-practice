" vim-practice — plugin/vim-practice.vim
" Install: Plug 'ilia-murzinov/vim-practice'

if exists('g:vim_practice_loaded') | finish | endif
let g:vim_practice_loaded = 1

let s:root           = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let s:challenges_dir = s:root . '/challenges'
let s:tmp            = s:root . '/.tmp'


" Insert-exit aliases (optional): substring count adjusted on top of CSI-collapsed length.
if !exists('g:vim_practice_insert_escape')
  let g:vim_practice_insert_escape = []
endif

" Fold Esc + CSI / Esc O. into ONE key; never touches bare jj (those are ASCII j+j).
if !exists('g:vim_practice_collapse_csi_escapes')
  let g:vim_practice_collapse_csi_escapes = 1
endif

" ─── pure helpers — exposed via g:vp dict so tests can call them ─────────────

let g:vp = {}

function! s:macro_strlen_with_esc_sequences_collapsed(seq) abort
  if empty(get(g:, 'vim_practice_collapse_csi_escapes', 1))
    return strlen(a:seq)
  endif
  let t = a:seq
  " CSI: ESC [ param* intermediate* final  (@ through ~ last byte).
  let pat_csi = "\<Esc>\\[[0-9:;<=>+.]*[ -/]*[@-~]"
  let prev = '__'
  while t !=# prev
    let prev = t
    let t = substitute(t, pat_csi, "\<Esc>", 'g')
  endwhile
  " SS3: ESC O followed by one byte (common on some keypad/cursor setups).
  let t = substitute(t, "\<Esc>O.", "\<Esc>", 'g')
  return strlen(t)
endfunction

function! s:normalize_insert_escape_aliases(aliases) abort
  let al = empty(a:aliases) ? [] : copy(a:aliases)
  let t = type(al)
  if t == type('')
    let al = empty(al) ? [] : [al]
  elseif t != type([])
    let al = []
  endif
  return filter(copy(al), 'strlen(v:val) > 1')
endfunction

function! s:escape_alias_list() abort
  return s:normalize_insert_escape_aliases(g:vim_practice_insert_escape)
endfunction

" Non-overlapping, greedy left→right counts of needle in haystack (byte-wise).
function! s:macro_count_occurrences(haystack, needle) abort
  let nl = strlen(a:needle)
  let c = 0
  let i = 0
  while i + nl <= strlen(a:haystack)
    if strpart(a:haystack, i, nl) ==# a:needle
      let c += 1
      let i += nl
    else
      let i += 1
    endif
  endwhile
  return c
endfunction

function! g:vp.macro_key_count(raw, ...) abort
  let keys = s:macro_strlen_with_esc_sequences_collapsed(a:raw)
  let aliases = a:0 > 0 ? s:normalize_insert_escape_aliases(a:1)
        \                       : s:escape_alias_list()
  for needle in aliases
    let oc = s:macro_count_occurrences(a:raw, needle)
    if oc > 0
      let keys -= oc * (strlen(needle) - 1)
    endif
  endfor
  return keys
endfunction

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
    call s:hl('  No challenges found in ' . s:challenges_dir, 'WarningMsg') | return
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

" ─── :VimRandom ─────────────────────────────────────────────────────────────

function! s:random() abort
  if !executable('python3')
    call s:hl('  python3 not found — required for :VimRandom', 'ErrorMsg') | return
  endif
  let gen = s:root . '/generate.py'
  if !filereadable(gen)
    call s:hl('  generate.py not found in ' . s:root, 'ErrorMsg') | return
  endif
  let out = s:tmp . '/random'
  call system('python3 ' . shellescape(gen) . ' ' . shellescape(out))
  if v:shell_error
    call s:hl('  Challenge generation failed', 'ErrorMsg') | return
  endif
  call s:load_dir(out)
endfunction

" ─── :VimChallenge {n} ───────────────────────────────────────────────────────

function! s:load(n) abort
  let all = g:vp.challenges()
  if empty(all)
    call s:hl('  No challenges found in ' . s:challenges_dir, 'ErrorMsg') | return
  endif
  let idx = a:n - 1
  if idx < 0 || idx >= len(all)
    call s:hl('  No challenge ' . a:n . ' — use :VimList (' . len(all) . ' available)', 'ErrorMsg')
    return
  endif
  call s:load_dir(all[idx])
endfunction

function! s:load_dir(dir) abort
  let start  = a:dir . '/start.txt'
  let target = a:dir . '/target.txt'

  if !filereadable(start)
    call s:hl('  Missing start.txt in ' . a:dir, 'ErrorMsg') | return
  endif
  if !filereadable(target)
    call s:hl('  Missing target.txt in ' . a:dir, 'ErrorMsg') | return
  endif

  call mkdir(s:tmp, 'p')
  let work = g:vp.work_path(a:dir)
  call writefile(readfile(start), work)
  call setreg('q', '')

  execute 'tabnew ' . fnameescape(work)

  let t:vp_dir     = a:dir
  let t:vp_target  = target
  let t:vp_optimal = str2nr(g:vp.meta(a:dir, 'OPTIMAL'))
  let t:vp_name    = fnamemodify(a:dir, ':t')
  setlocal noswapfile
  execute 'rightbelow split ' . fnameescape(target)
  setlocal readonly nomodifiable noswapfile bufhidden=hide
  setlocal statusline=\ TARGET\ (read\ only)
  wincmd p

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

  let regq = getreg('q')
  let keys_raw   = strlen(regq)
  let keys_score = g:vp.macro_key_count(regq)
  let keys    = keys_score
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
  if keys_raw != keys_score
    echo printf('  (%d bytes recorded in q → %d Esc/keys for scoring)',
          \ keys_raw, keys_score)
  endif
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
  echo '  Macro (q)   : ' . regq
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
nnoremap <Space>vl :VimList<CR>
nnoremap <Space>vn :VimRandom<CR>
nnoremap <Space>vc :VimCheck<CR>
nnoremap <Space>vr :VimReset<CR>

" ─── commands ────────────────────────────────────────────────────────────────

command!          VimList            call s:list()
command!          VimRandom          call s:random()
command! -nargs=1 VimChallenge       call s:load(<args>)
command! -nargs=1 VimLoadDir         call s:load_dir(<q-args>)
command!          VimCheck           call s:check()
command!          VimReset           call s:reset()

