" =============================================================================
" Filename: autoload/thumbnail/content.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/11/24 23:03:21.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#content#get(bufnr, width, height) abort
  let bufname =  bufname(a:bufnr)
  if bufloaded(a:bufnr) && bufexists(a:bufnr)
    let lines = getbufline(a:bufnr, 1, a:height - 1)
  elseif bufname !=# '' && filereadable(bufname)
    let lines = readfile(bufname, '', a:height - 1)
  else
    let lines = []
  endif
  let name = bufname
  let abbrnames = []
  call add(abbrnames, substitute(bufname, expand('~'), '~', ''))
  let updir = substitute(expand('%:p:h'), '[^/]*$', '', '')
  call add(abbrnames, substitute(bufname, escape(updir, '.$*'), '../', ''))
  let upupdir = substitute(updir, '[^/]*/$', '', '')
  call add(abbrnames, substitute(bufname, escape(upupdir, '.$*'), '../../', ''))
  for abbrname in abbrnames
    let name = len(name) > len(abbrname) ? abbrname : name
  endfor
  if match(lines, '[\x00-\x08]') >= 0
    let lines = repeat([''], a:height / 2 - 2)
    call extend(lines, [repeat(' ', (a:width - 4) / 2 - 7) . '[Binary file]'])
  endif
  call insert(lines, thumbnail#string#truncate_smart(name ==# '' ? '[No Name]' : name,
        \ a:width - 4, (a:width - 4) * 3 / 5, ' .. '))
  return { 'contents': map(lines, 'thumbnail#string#truncate(substitute(v:val,"\t","' .
        \ repeat(' ', getbufvar(a:bufnr, '&tabstop')) .
        \ '","g"),' . (a:width - 4) . ')'),
        \ 'name': name }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
