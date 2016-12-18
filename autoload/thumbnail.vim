" =============================================================================
" Filename: autoload/thumbnail.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/18 08:45:03.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#new(args) abort
  let [isnewbuffer, command, ftconfig] = thumbnail#argument#parse(a:args)
  try | silent execute command | catch | return | endtry
  let b:thumbnail = thumbnail#controller#new(ftconfig)
  call b:thumbnail.gather()
  if b:thumbnail.empty()
    if isnewbuffer
      bdelete!
    endif
    enew
    return
  endif
  call b:thumbnail.prepare()
  call b:thumbnail.redraw()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
