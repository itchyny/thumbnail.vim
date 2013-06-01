" =============================================================================
" Filename: syntax/thumbnail.vim
" Version: 0.1
" Author: itchyny
" License: MIT License
" Last Change: 2013/06/01 18:37:41.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax match ThumbnailSelect '\[|.\{-}|\]' contains=ThumbnailSMarker

if has('conceal') && (!exists('b:thumbnail_conceal') || b:thumbnail_conceal)
  syntax match ThumbnailSMarker '\[|\||\]' contained conceal
  syntax match ThumbnailMarker '\[\\\|\\\]' conceal
  setlocal conceallevel=3
else
  syntax match ThumbnailSMarker '\[|\||\]' contained
  syntax match ThumbnailMarker '\[\\\|\\\]'
endif

highlight ThumbnailSelect term=none cterm=none ctermbg=235 gui=none guibg=#262626
highlight default link ThumbnailSMarker Ignore
highlight default link ThumbnailMarker Ignore

setlocal nocursorcolumn nocursorline

let b:current_syntax = 'thumbnail'

