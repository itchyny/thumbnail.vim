" =============================================================================
" Filename: autoload/thumbnail/autocmd.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/18 03:05:42.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#autocmd#new() abort

  if &l:filetype ==# 'thumbnail'
    return
  endif

  augroup thumbnail-update
    autocmd!
    autocmd BufEnter,BufWritePost,VimResized,ColorScheme *
          \ call s:update_visible(expand('<abuf>'))
  augroup END

  augroup thumbnail-buffer
    autocmd ColorScheme <buffer>
          \ call thumbnail#setlocal#filetype_force()
    autocmd WinEnter,WinLeave,VimResized,ColorScheme <buffer>
          \   if exists('b:thumbnail')
          \ |   call b:thumbnail.update()
          \ | endif
    autocmd CursorMoved <buffer>
          \ call b:thumbnail.action('cursor_moved')
    autocmd CursorMovedI <buffer>
          \ call b:thumbnail.action('update_filter')
  augroup END

endfunction

function! s:update_visible(bufnr) abort
  let nr = -1
  let newnr = str2nr(a:bufnr)
  if bufname(newnr) ==# '[Command Line]'
    return
  endif
  for buf in tabpagebuflist()
    if type(getbufvar(buf, 'thumbnail')) == type({}) && buf != newnr
      let nr = buf
      break
    endif
  endfor
  if nr == -1
    return
  endif
  let winnr = bufwinnr(nr)
  let newbuf = bufwinnr(str2nr(a:bufnr))
  let currentbuf = bufwinnr(bufnr('%'))
  execute winnr 'wincmd w'
  call thumbnail#setlocal#filetype_force()
  call b:thumbnail.update()
  if winnr != newbuf && newbuf != -1
    call cursor(1, 1)
    execute newbuf 'wincmd w'
  elseif winnr != currentbuf && currentbuf != -1
    call cursor(1, 1)
    execute currentbuf 'wincmd w'
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
