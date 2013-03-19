" =============================================================================
" Filename: thumbnail.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/03/19 17:15:32.
" =============================================================================
"

let s:Prelude = vital#of('thumbnail.vim').import('Prelude')

function! s:initbuffer()
  let b = {}
  let b.height = winheight(0)
  let b.width = winwidth(0)
  let b.bufnr = []
  let b.bufname = []
  let b.bufprev = []
  let b.buffirstlinelen = []
  for i in range(1, bufnr('$'))
    if bufloaded(i) && bufexists(i) && buflisted(i) && bufname(i) != ''
      call add(b.bufnr, i)
      call add(b.bufname, bufname(i))
    endif
  endfor
  let b.bufleft_select = '[|'
  let b.bufright_select = '|]'
  let b.bufleft = '  '
  let b.bufright = '  '
  let b.num_height = 1
  let b.num_width = len(b.bufname)
  let b.thumbnail_height = min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
  let b.thumbnail_width = min([b.thumbnail_height * 3, b.width * 4 / 5 / b.num_width])
  while b.thumbnail_height * 2 > b.thumbnail_width
    let b.num_height += 1
    let b.num_width = (len(b.bufname) + 1) / b.num_height
    let b.thumbnail_height = min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
    let b.thumbnail_width = min([b.thumbnail_height * 5, b.width * 4 / 5 / b.num_width])
  endwhile
  let b.offset_top = (b.height - b.num_height * b.thumbnail_height) / (b.num_height + 1)
  let b.offset_left = (b.width - b.num_width * b.thumbnail_width) / (b.num_width + 1)
  let b.select_i = 0
  let b.select_j = 0
  for i in b.bufnr
    let s = map(getbufline(i, 1, b.thumbnail_height),
          \ 's:Prelude.truncate(v:val . "' . repeat(' ', b.thumbnail_width) . '", ' .
          \ (b.thumbnail_width - 4) . ')')
    call add(b.bufprev, s)
    call add(b.buffirstlinelen, len(s[0]))
  endfor
  nnoremap <buffer><silent> h :<C-u>ThumbnailLeft<CR>
  nnoremap <buffer><silent> l :<C-u>ThumbnailRight<CR>
  nnoremap <buffer><silent> j :<C-u>ThumbnailDown<CR>
  nnoremap <buffer><silent> k :<C-u>ThumbnailUp<CR>
  nnoremap <buffer><silent> <CR> :<C-u>ThumbnailSelect<CR>
  return b
endfunction

function! s:initthumbnail()
  tabnew
  let b = s:initbuffer()
  let b:thumbnail = b
  call s:updatethumbnail()
endfunction

function! s:updatethumbnail()
  if !exists('b:thumbnail')
    return
  endif
  setlocal modifiable noreadonly
  silent % delete _
  let b = b:thumbnail
  let th = b.height * 2 / 5
  let of = (b.height - th * 2) / 3
  let s = []
  for i in range(b.num_height)
    for j in range(b.offset_top)
      call add(s, '')
    endfor
    for k in range(b.thumbnail_height)
      let ss = ''
      for j in range(b.num_width)
        let l = i * b.num_width + j
        if l < len(b.bufprev) && k < len(b.bufprev[l])
          let contents = b.bufprev[l][k]
        else
          let contents = repeat(' ', b.thumbnail_width - 4)
        endif
        if b.select_i == i && b.select_j == j
          let ss .= repeat(' ', b.offset_left) . b.bufleft_select . contents . b.bufright_select
        else
          let ss .= repeat(' ', b.offset_left) . b.bufleft . contents . b.bufright
        endif
      endfor
      call add(s, ss)
    endfor
  endfor
  call append(0, s)
  let offset = 0
  for j in range(b.select_j)
    let ind = b.select_i * b.num_width + j
    let offset += b.buffirstlinelen[ind] + b.offset_left + 4
  endfor
  call cursor(b.select_i * (b.offset_top + b.thumbnail_height) + b.offset_top + 1,
        \ offset + b.offset_left + 3)
  setlocal nomodifiable buftype=nofile noswapfile readonly nonumber
        \ bufhidden=hide nobuflisted filetype=thumbnail
endfunction

function! s:thumbnail_left()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_j > 0
    let b.select_j -= 1
    call s:updatethumbnail()
  endif
endfunction

function! s:thumbnail_right()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_j + 1 < b.num_width
    let b.select_j += 1
    if s:thumbnail_select_exists()
      call s:updatethumbnail()
    else
      let b.select_j -= 1
    endif
  endif
endfunction

function! s:thumbnail_up()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_i > 0
    let b.select_i -= 1
    call s:updatethumbnail()
  endif
endfunction

function! s:thumbnail_down()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_i + 1 < b.num_height
    let b.select_i += 1
    if s:thumbnail_select_exists()
      call s:updatethumbnail()
    else
      let b.select_i -= 1
    endif
  endif
endfunction

function! s:thumbnail_exists(i)
  return 0 <= a:i && a:i < len(b:thumbnail.bufname)
endfunction

function! s:thumbnail_select_exists()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  return 0 <= i && i < len(b:thumbnail.bufname)
endfunction

function! s:thumbnail_select()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  if s:thumbnail_exists(i)
    let buf = b.bufname[i]
    let num = bufnr(escape(buf, '*[]?{}, '))
    if num > -1
      execute num 'buffer!'
    endif
  endif
  echo b.bufname[i]
endfunction

command! Thumbnail call s:initthumbnail()
command! ThumbnailLeft call s:thumbnail_left()
command! ThumbnailRight call s:thumbnail_right()
command! ThumbnailDown call s:thumbnail_down()
command! ThumbnailUp call s:thumbnail_up()
command! ThumbnailSelect call s:thumbnail_select()

