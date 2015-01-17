" =============================================================================
" Filename: plugin/thumbnail.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/01/17 13:40:47.
" =============================================================================

if exists('g:loaded_thumbnail') || v:version < 700
  finish
endif
let g:loaded_thumbnail = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,thumbnail#complete
      \ Thumbnail call thumbnail#new(<q-args>)

" <Plug>(thumbnail)
nnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>
vnoremap <silent> <Plug>(thumbnail) :<C-u>Thumbnail<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
