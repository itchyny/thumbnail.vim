" =============================================================================
" Filename: plugin/thumbnail.vim
" Version: 0.5
" Author: itchyny
" License: MIT License
" Last Change: 2014/03/16 00:23:47.
" =============================================================================

if exists('g:loaded_thumbnail') && g:loaded_thumbnail
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,thumbnail#complete
      \ Thumbnail call thumbnail#new(<q-args>)

" <Plug>(thumbnail)
nnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>
vnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>

let g:loaded_thumbnail = 1

let &cpo = s:save_cpo
unlet s:save_cpo
