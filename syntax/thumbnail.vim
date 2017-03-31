" =============================================================================
" Filename: syntax/thumbnail.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/04/01 00:46:38.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

syntax match ThumbnailSelect '\[|.\{-}|\]' contains=ThumbnailSelectMarker,ThumbnailTab
syntax match ThumbnailVisual '\[\^.\{-}\^\]' contains=ThumbnailVisualMarker,ThumbnailTab

if has('conceal') && get(get(get(get(b:, 'thumbnail', {}), 'view', {}), 'marker', {}), 'conceal', 0)
  syntax match ThumbnailSelectMarker '\[|\||\]' contained conceal
  syntax match ThumbnailVisualMarker '\[\^\|\^\]' contained conceal
  syntax match ThumbnailMarker '\[\\\|\\\]' conceal
else
  syntax match ThumbnailSelectMarker '\[|\||\]' contained
  syntax match ThumbnailVisualMarker '\[\^\|\^\]' contained
  syntax match ThumbnailMarker '\[\\\|\\\]'
endif
if has('conceal')
  syntax match ThumbnailTab '\t' conceal
else
  syntax match ThumbnailTab '\t'
endif

let s:gui_color = {
      \ 'black'          : '#000000',
      \ 'white'          : '#ffffff',
      \
      \ 'darkestgreen'   : '#005f00',
      \ 'darkgreen'      : '#008700',
      \ 'mediumgreen'    : '#5faf00',
      \ 'brightgreen'    : '#afdf00',
      \
      \ 'darkestcyan'    : '#005f5f',
      \ 'mediumcyan'     : '#87dfff',
      \
      \ 'darkestblue'    : '#005f87',
      \ 'darkblue'       : '#0087af',
      \
      \ 'darkestred'     : '#5f0000',
      \ 'darkred'        : '#870000',
      \ 'mediumred'      : '#af0000',
      \ 'brightred'      : '#df0000',
      \ 'brightestred'   : '#ff0000',
      \
      \ 'darkestpurple'  : '#5f00af',
      \ 'mediumpurple'   : '#875fdf',
      \ 'brightpurple'   : '#dfdfff',
      \
      \ 'brightorange'   : '#ff8700',
      \ 'brightestorange': '#ffaf00',
      \
      \ 'gray0'          : '#121212',
      \ 'gray1'          : '#262626',
      \ 'gray2'          : '#303030',
      \ 'gray3'          : '#4e4e4e',
      \ 'gray4'          : '#585858',
      \ 'gray5'          : '#606060',
      \ 'gray6'          : '#808080',
      \ 'gray7'          : '#8a8a8a',
      \ 'gray8'          : '#9e9e9e',
      \ 'gray9'          : '#bcbcbc',
      \ 'gray10'         : '#d0d0d0',
      \
      \ 'yellow'         : '#b58900',
      \ 'orange'         : '#cb4b16',
      \ 'red'            : '#dc322f',
      \ 'magenta'        : '#d33682',
      \ 'violet'         : '#6c71c4',
      \ 'blue'           : '#268bd2',
      \ 'cyan'           : '#2aa198',
      \ 'green'          : '#859900',
      \ }

let s:term = has('gui_running') ? 'gui' : 'cterm'
let s:fg_color = synIDattr(synIDtrans(hlID('Normal')), 'fg', s:term)
let s:bg_color = synIDattr(synIDtrans(hlID('Normal')), 'bg', s:term)
if s:term ==# 'cterm'
  function! s:rgb(nr)
    let x = a:nr * 1
    if x < 8
      let [b, rg] = [x / 4, x % 4]
      let [g, r] = [rg / 2, rg % 2]
      return [r * 3, g * 3, b * 3]
    elseif x == 8
      return [4, 4, 4]
    elseif x < 16
      let y = x - 8
      let [b, rg] = [y / 4, y % 4]
      let [g, r] = [rg / 2, rg % 2]
      return [r * 5, g * 5, b * 5]
    elseif x < 232
      let y = x - 16
      let [rg, b] = [y / 6, y % 6]
      let [r, g] = [rg / 6, rg % 6]
      return [r, g, b]
    else
      let k = (x - 232) * 5 / 23
      return [k, k, k]
    endif
  endfunction
  function! s:gen_color(fg, bg, weightfg, weightbg)
    let fg = a:fg < 0 || a:fg ==# '' ? (&bg ==# 'light' ?  232 : 255) : a:fg
    let bg = a:bg < 0 || a:bg ==# '' ? (&bg ==# 'light' ?  255 : 232) : a:bg
    let fg_rgb = s:rgb(fg)
    let bg_rgb = s:rgb(bg)
    if fg > 231 && bg > 231
      let color = (fg * a:weightfg + bg * a:weightbg) / (a:weightfg + a:weightbg)
    else
      let color_rgb = map([0, 1, 2], '(fg_rgb[v:val] * a:weightfg + bg_rgb[v:val] * a:weightbg) / (a:weightfg + a:weightbg)')
      let color = ((color_rgb[0] * 6 + color_rgb[1]) * 6 + color_rgb[2]) + 16
    endif
    return color
  endfunction
  exec 'highlight ThumbnailVisual term=none cterm=none ctermbg=' . s:gen_color(s:fg_color, s:bg_color, 1, 4)
  exec 'highlight ThumbnailSelect term=none cterm=none ctermbg=' . s:gen_color(s:fg_color, s:bg_color, 1, 2)
else
  function! s:gen_color(fg, bg, weightfg, weightbg)
    let fg_rgb = map(matchlist(a:fg[0] ==# '#' ? a:fg : get(s:gui_color, a:fg, ''), '#\(..\)\(..\)\(..\)')[1:3], '("0x".v:val) + 0')
    let bg_rgb = map(matchlist(a:bg[0] ==# '#' ? a:bg : get(s:gui_color, a:bg, ''), '#\(..\)\(..\)\(..\)')[1:3], '("0x".v:val) + 0')
    if len(fg_rgb) != 3 | let fg_rgb = &background ==# 'light' ? [0x12, 0x12, 0x12] : [0xe4, 0xe4, 0xe4] | endif
    if len(bg_rgb) != 3 | let bg_rgb = &background ==# 'light' ? [0xe4, 0xe4, 0xe4] : [0x12, 0x12, 0x12] | endif
    let color_rgb = map(map([0, 1, 2], '(fg_rgb[v:val] * a:weightfg + bg_rgb[v:val] * a:weightbg) / (a:weightfg + a:weightbg)'), 'v:val < 0 ? 0 : v:val > 0xff ? 0xff : v:val')
    let color = printf('0x%02x%02x%02x', color_rgb[0], color_rgb[1], color_rgb[2]) + 0
    if color < 0 || 0xffffff < color | let color = &background ==# 'light' ? 0xbcbcbc : 0x3a3a3a | endif
    return printf('#%06x', color)
  endfunction
  exec 'highlight ThumbnailVisual term=none gui=none guibg=' . s:gen_color(s:fg_color, s:bg_color, 1, 4)
  exec 'highlight ThumbnailSelect term=none gui=none guibg=' . s:gen_color(s:fg_color, s:bg_color, 1, 2)
endif

highlight default link ThumbnailSelectMarker Ignore
highlight default link ThumbnailVisualMarker Ignore
highlight default link ThumbnailMarker Ignore
highlight default link ThumbnailTab Ignore

unlet! s:gui_color s:term s:fg_color s:bg_color

let b:current_syntax = 'thumbnail'

let &cpo = s:save_cpo
unlet s:save_cpo
