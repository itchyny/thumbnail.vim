" =============================================================================
" Filename: autoload/thumbnail/string.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/05 08:35:58.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" The following codes were imported from vital.vim
" https://github.com/vim-jp/vital.vim (Public Domain)
function! thumbnail#string#truncate(str, width) abort
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master
  if a:str =~# '^[\x20-\x7e]*$'
    return len(a:str) < a:width ? printf('%-'.a:width.'s', a:str) : strpart(a:str, 0, a:width)
  endif
  let ret = a:str
  let width = thumbnail#string#strdisplaywidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = thumbnail#string#strdisplaywidth(ret)
  endif
  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif
  return ret
endfunction

function! thumbnail#string#truncate_smart(str, max, footer_width, separator) abort
  let width = thumbnail#string#strdisplaywidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - thumbnail#string#strdisplaywidth(a:separator) - a:footer_width
    let ret = s:strwidthpart(a:str, header_width) . a:separator
          \ . s:strwidthpart_reverse(a:str, a:footer_width)
  endif
  return thumbnail#string#truncate(ret, a:max)
endfunction

function! s:strwidthpart(str, width) abort
  let str = tr(a:str, "\t", ' ')
  let vcol = a:width + 2
  return matchstr(str, '.*\%<' . (vcol < 0 ? 0 : vcol) . 'v')
endfunction

function! s:strwidthpart_reverse(str, width) abort
  let str = tr(a:str, "\t", ' ')
  let vcol = strdisplaywidth(str) - a:width
  return matchstr(str, '\%>' . (vcol < 0 ? 0 : vcol) . 'v.*')
endfunction

function! thumbnail#string#strdisplaywidth(str) abort
  return strdisplaywidth(a:str)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
