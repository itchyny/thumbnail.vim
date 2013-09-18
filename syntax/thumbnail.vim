" =============================================================================
" Filename: syntax/thumbnail.vim
" Version: 0.5
" Author: itchyny
" License: MIT License
" Last Change: 2013/09/18 17:54:34.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax match ThumbnailSelect '\[|.\{-}|\]' contains=ThumbnailSelectMarker
syntax match ThumbnailVisual '\[\^.\{-}\^\]' contains=ThumbnailVisualMarker

if has('conceal') && (!exists('b:thumbnail_conceal') || b:thumbnail_conceal)
  syntax match ThumbnailSelectMarker '\[|\||\]' contained conceal
  syntax match ThumbnailVisualMarker '\[\^\|\^\]' contained conceal
  syntax match ThumbnailMarker '\[\\\|\\\]' conceal
  if exists('&conceallevel')
    setlocal conceallevel=3
  endif
  let b:thumbnail_conceal = 1
else
  syntax match ThumbnailSelectMarker '\[|\||\]' contained
  syntax match ThumbnailVisualMarker '\[\^\|\^\]' contained
  syntax match ThumbnailMarker '\[\\\|\\\]'
endif

highlight ThumbnailSelect term=none cterm=none ctermbg=236 gui=none guibg=#2c2c2c
highlight ThumbnailVisual term=none cterm=none ctermbg=234 gui=none guibg=#1c1c1c
highlight default link ThumbnailSelectMarker Ignore
highlight default link ThumbnailVisualMarker Ignore
highlight default link ThumbnailMarker Ignore

setlocal nocursorcolumn nocursorline

let b:current_syntax = 'thumbnail'

