" =============================================================================
" Filename: plugin/thumbnail.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/06 21:23:05.
" =============================================================================

if exists('g:loaded_thumbnail') || v:version < 700
  finish
endif
let g:loaded_thumbnail = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,thumbnail#argument#complete
      \ Thumbnail call thumbnail#new(<q-args>)

nnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>
vnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
