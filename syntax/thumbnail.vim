" =============================================================================
" Filename: syntax/thumbnail.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/03/20 07:25:29.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax match ThumbnailSelect '\[|.*|\]' contains=ThumbnailSMarker 
syntax match ThumbnailSMarker '\[|\||\]' contained
syntax match ThumbnailMarker '\[\\\|\\\]'

highlight ThumbnailSelect term=none cterm=none ctermbg=235 gui=none guibg=#262626
highlight default link ThumbnailSMarker Ignore
highlight default link ThumbnailMarker Ignore

setlocal nocursorcolumn nocursorline

let b:current_syntax = 'thumbnail'

