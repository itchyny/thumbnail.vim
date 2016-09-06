" =============================================================================
" Filename: autoload/thumbnail/string.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/09/07 05:29:55.
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
  if a:width <= 0
    return ''
  endif
  let strarr = split(a:str, '\zs')
  let width = thumbnail#string#strdisplaywidth(a:str)
  let index = len(strarr)
  let diff = (index + 1) / 2
  let rightindex = index - 1
  while width > a:width
    let index = max([rightindex - diff + 1, 0])
    let partwidth = thumbnail#string#strdisplaywidth(join(strarr[(index):(rightindex)], ''))
    if width - partwidth >= a:width || diff <= 1
      let width -= partwidth
      let rightindex = index - 1
    endif
    if diff > 1
      let diff = diff / 2
    endif
  endwhile
  return index ? join(strarr[:index - 1], '') : ''
endfunction

function! s:strwidthpart_reverse(str, width) abort
  if a:width <= 0
    return ''
  endif
  let strarr = split(a:str, '\zs')
  let width = thumbnail#string#strdisplaywidth(a:str)
  let strlen = len(strarr)
  let diff = (strlen + 1) / 2
  let leftindex = 0
  let index = -1
  while width > a:width
    let index = min([leftindex + diff, strlen]) - 1
    let partwidth = thumbnail#string#strdisplaywidth(join(strarr[(leftindex):(index)], ''))
    if width - partwidth >= a:width || diff <= 1
      let width -= partwidth
      let leftindex = index + 1
    endif
    if diff > 1
      let diff = diff / 2
    endif
  endwhile
  return index < strlen ? join(strarr[(index + 1):], '') : ''
endfunction

if exists('*strdisplaywidth')
  function! thumbnail#string#strdisplaywidth(str) abort
    return strdisplaywidth(a:str)
  endfunction
else
  function! thumbnail#string#strdisplaywidth(str) abort
    if a:str =~# '^[\x00-\x7f]*$'
      return 2 * strlen(a:str)
            \ - strlen(substitute(a:str, '[\x00-\x08\x0b-\x1f\x7f]', '', 'g'))
    endif
    let mx_first = '^\(.\)'
    let str = a:str
    let width = 0
    while 1
      let ucs = char2nr(substitute(str, mx_first, '\1', ''))
      if ucs == 0
        break
      endif
      let width += s:_wcwidth(ucs)
      let str = substitute(str, mx_first, '', '')
    endwhile
    return width
  endfunction

  " UTF-8 only.
  function! s:_wcwidth(ucs) abort
    let ucs = a:ucs
    if ucs > 0x7f && ucs <= 0xff
      return 4
    endif
    if ucs <= 0x08 || 0x0b <= ucs && ucs <= 0x1f || ucs == 0x7f
      return 2
    endif
    if (ucs >= 0x1100
          \  && (ucs <= 0x115f
          \  || ucs == 0x2329
          \  || ucs == 0x232a
          \  || (ucs >= 0x2190 && ucs <= 0x2194)
          \  || (ucs >= 0x2500 && ucs <= 0x2573)
          \  || (ucs >= 0x2580 && ucs <= 0x25ff)
          \  || (ucs >= 0x2e80 && ucs <= 0xa4cf && ucs != 0x303f)
          \  || (ucs >= 0xac00 && ucs <= 0xd7a3)
          \  || (ucs >= 0xf900 && ucs <= 0xfaff)
          \  || (ucs >= 0xfe30 && ucs <= 0xfe6f)
          \  || (ucs >= 0xff00 && ucs <= 0xff60)
          \  || (ucs >= 0xffe0 && ucs <= 0xffe6)
          \  || (ucs >= 0x20000 && ucs <= 0x2fffd)
          \  || (ucs >= 0x30000 && ucs <= 0x3fffd)
          \  ))
      return 2
    endif
    return 1
  endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo
