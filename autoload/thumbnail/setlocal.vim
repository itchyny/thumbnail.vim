" =============================================================================
" Filename: autoload/thumbnail/setlocal.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/06 21:39:41.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#setlocal#new() abort
  setlocal nomodifiable buftype=nofile noswapfile readonly
        \ bufhidden=hide wrap nowrap nobuflisted nofoldenable foldcolumn=0
        \ nolist completefunc=thumbnail#complete omnifunc=
        \ nocursorcolumn nocursorline nonumber nomodeline
  if exists('&conceallevel')
    setlocal conceallevel=3
  endif
  if exists('&concealcursor')
    setlocal concealcursor=nvic
  endif
  if v:version > 704 || v:version == 704 && has('patch073')
    setlocal undolevels=-1
  endif
  if exists('&colorcolumn')
    setlocal colorcolumn=
  endif
  if exists('&relativenumber')
    setlocal norelativenumber
  endif
  call thumbnail#setlocal#filetype()
endfunction

function! thumbnail#setlocal#modifiable() abort
  setlocal modifiable noreadonly
endfunction

function! thumbnail#setlocal#nomodifiable() abort
  setlocal nomodifiable readonly
endfunction

function! thumbnail#setlocal#filetype() abort
  if &l:filetype !=# 'thumbnail'
    setlocal filetype=thumbnail
  endif
endfunction

function! thumbnail#setlocal#filetype_force() abort
  setlocal filetype=
  setlocal filetype=thumbnail
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
