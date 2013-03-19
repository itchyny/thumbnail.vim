" =============================================================================
" Filename: thumbnail.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/03/20 00:02:40.
" =============================================================================
"

let s:Prelude = vital#of('thumbnail.vim').import('Prelude')

function! s:initbuffer()
  let b = {}
  let b.height = winheight(0)
  let b.width = winwidth(0)
  let b.bufs = []
  for i in range(1, bufnr('$'))
    let name = bufname(i)
    if len(name) == 0
      continue
    endif
    call add(b.bufs, {
    \ 'bufnr': i,
    \ 'bufname': name,
    \ 'loaded': bufloaded(i) && bufexists(i) && name != '',
    \})
  endfor
  if len(b.bufs) == 0
    silent bdelete!
    return b
  endif
  let b.buffirstlinelen = []
  let b.bufleft_select = '[|'
  let b.bufright_select = '|]'
  let b.bufleft = '  '
  let b.bufright = '  '
  let b.num_height = 1
  let b.num_width = len(b.bufs)
  let b.thumbnail_height =
        \ min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
  let b.thumbnail_width =
        \ min([b.thumbnail_height * 5, b.width * 4 / 5 / b.num_width])
  while b.thumbnail_height * 2 > b.thumbnail_width
    let b.num_height += 1
    let b.num_width = (len(b.bufs) + 1) / b.num_height
    let b.thumbnail_height =
          \ min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
    let b.thumbnail_width =
          \ min([b.thumbnail_height * 5, b.width * 4 / 5 / b.num_width])
  endwhile
  let b.offset_top =
        \ (b.height - b.num_height * b.thumbnail_height) / (b.num_height + 1)
  let b.offset_left =
        \ (b.width - b.num_width * b.thumbnail_width) / (b.num_width + 1)
  let b.select_i = 0
  let b.select_j = 0
  for buf in b.bufs
    if buf.loaded
      let lines = getbufline(buf.bufnr, 1, b.thumbnail_height)
    elseif buf.bufname != '' && filereadable(buf.bufname)
      let lines = readfile(buf.bufname, '', b.thumbnail_height)
    else
      continue
    endif
    let s = map(lines,
          \ 's:Prelude.truncate(substitute(v:val, "\t",' .
          \ string(repeat(' ', getbufvar(buf.bufnr, '&tabstop'))) .
          \ ', "g") . "' . '", ' .  (b.thumbnail_width - 4) . ')')
    call extend(buf, {
          \ 'contents': s
          \ })
    call add(b.buffirstlinelen, len(s) > 0 ? len(s[0]) : 0)
  endfor
  call s:initmapping()
  return b
endfunction

function! s:initmapping()

  nnoremap <buffer><silent> <Plug>(thumbnail_move_left)
        \ :<C-u>call <SID>thumbnail_left()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_right)
        \ :<C-u>call <SID>thumbnail_right()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_down)
        \ :<C-u>call <SID>thumbnail_down()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_up)
        \ :<C-u>call <SID>thumbnail_up()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_select)
        \ :<C-u>call <SID>thumbnail_select()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close)
        \ :<C-u>bdelete!<CR>

  nmap <buffer> h <Plug>(thumbnail_move_left)
  nmap <buffer> l <Plug>(thumbnail_move_right)
  nmap <buffer> j <Plug>(thumbnail_move_down)
  nmap <buffer> k <Plug>(thumbnail_move_up)
  nmap <buffer> q <Plug>(thumbnail_close)
  nmap <buffer> <Left> <Plug>(thumbnail_move_left)
  nmap <buffer> <Right> <Plug>(thumbnail_move_right)
  nmap <buffer> <Down> <Plug>(thumbnail_move_down)
  nmap <buffer> <Up> <Plug>(thumbnail_move_up)

  nmap <buffer> <CR> <Plug>(thumbnail_select)

endfunction

function! s:initthumbnail()
  let b = s:initbuffer()
  if len(b.bufs) > 0
    let b:thumbnail = b
    silent call s:updatethumbnail()
  endif
endfunction

function! s:newthumbnail()
  tabnew
  call s:initthumbnail()
  augroup Thumbnail
    autocmd BufEnter,WinEnter,BufWinEnter <buffer>
          \ silent call s:initthumbnail()
  augroup END
endfunction

function! s:updatethumbnail()
  if !exists('b:thumbnail')
    return
  endif
  setlocal modifiable noreadonly
  silent % delete _
  silent call cursor(1, 1)
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
        if l < len(b.bufs) && k < len(b.bufs[l].contents)
          let contents = b.bufs[l].contents[k]
        else
          let contents = repeat(' ', b.thumbnail_width - 4)
        endif
        if b.select_i == i && b.select_j == j
          let l = b.bufleft_select
          let r = b.bufright_select
        else
          let l = b.bufleft
          let r = b.bufright
        endif
        let ss .= repeat(' ', b.offset_left) . l . contents . r
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
  silent call cursor(b.select_i * (b.offset_top + b.thumbnail_height)
        \ + b.offset_top + 1, offset + b.offset_left + 3)
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
  return 0 <= a:i && a:i < len(b:thumbnail.bufs)
endfunction

function! s:thumbnail_select_exists()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  return 0 <= i && i < len(b:thumbnail.bufs)
endfunction

function! s:thumbnail_select()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  if s:thumbnail_exists(i)
    let buf = b.bufs[i].bufname
    let num = bufnr(escape(buf, '*[]?{}, '))
    if num > -1
      execute num 'buffer!'
    endif
  endif
endfunction

command! Thumbnail call s:newthumbnail()

