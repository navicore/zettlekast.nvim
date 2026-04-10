set rtp+=.

" Try sibling directory first (CI), then lazy.nvim path (local)
let s:plenary_candidates = [
  \ expand('<sfile>:p:h:h') .. '/../plenary.nvim',
  \ stdpath('data') .. '/lazy/plenary.nvim',
  \ ]

for s:dir in s:plenary_candidates
  if isdirectory(s:dir)
    execute 'set rtp+=' .. s:dir
    break
  endif
endfor

runtime plugin/plenary.vim
