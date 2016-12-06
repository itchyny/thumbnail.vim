" =============================================================================
" Filename: autoload/thumbnail/argument.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/06 21:18:04.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#argument#buffername(name) abort
  let buflist = []
  for i in range(tabpagenr('$'))
    call extend(buflist, tabpagebuflist(i + 1))
  endfor
  let matcher = 'bufname(v:val) =~# ("\\[" . a:name . "\\( \\d\\+\\)\\?\\]") && index(buflist, v:val) >= 0'
  let substituter = 'substitute(bufname(v:val), ".*\\(\\d\\+\\).*", "\\1", "") + 0'
  let bufs = map(filter(range(1, bufnr('$')), matcher), substituter)
  let index = 0
  while index(bufs, index) >= 0
    let index += 1
  endwhile
  return '[' . a:name . (len(bufs) && index ? ' ' . index : '') . ']'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
