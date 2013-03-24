" =============================================================================
" Filename: plugin/thumbnail.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/03/24 14:34:55.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! s:init_buffer(isnewtab)
  let b = {}
  let b.bufs = []
  for i in range(1, bufnr('$'))
    if (len(bufname(i)) == 0 && (!bufexists(i) || !bufloaded(i)
          \ || !getbufvar(i, '&modified'))) || !buflisted(i)
      continue
    endif
    call add(b.bufs, { 'bufnr': i })
  endfor
  if len(b.bufs) == 0
    if a:isnewtab
      silent bdelete!
    endif
    return b
  endif
  call s:thumbnail_arrangement(b)
  let b.select_i = 0
  let b.select_j = 0
  for buf in b.bufs
    let c = s:get_contents(buf.bufnr, b.thumbnail_width, b.thumbnail_height)
    call extend(buf, {
          \ 'contents': c,
          \ 'firstlinelength': len(c) > 0 ? len(c[0]) : b.thumbnail_width - 4
          \ })
  endfor
  call s:thumbnail_marker(b)
  call s:thumbnail_mapping()
  return b
endfunction

function! s:get_contents(nr, width, height)
  let bufname =  bufname(a:nr)
  if bufloaded(a:nr) && bufexists(a:nr)
    let lines = getbufline(a:nr, 1, a:height - 1)
  elseif bufname != '' && filereadable(bufname)
    let lines = readfile(bufname, '', a:height - 1)
  else
    let lines = []
  endif
  call insert(lines, s:truncate_smart(bufname == '' ? '[No Name]' : bufname,
        \ a:width - 4, (a:width - 4) / 2, '..'))
  let contents = map(lines,
        \ 's:truncate(substitute(v:val, "\t",' .
        \ string(repeat(' ', getbufvar(a:nr, '&tabstop'))) .
        \ ', "g") . "' . '", ' .  (a:width - 4) . ')')
  return contents
endfunction

function! s:thumbnail_arrangement(b)
  let b = a:b
  let l = len(b.bufs)
  let b.height = winheight(0)
  let b.width = winwidth(0)
  let b.num_height = 1
  let b.num_width = l
  let b.thumbnail_height =
        \ min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
  let b.thumbnail_width =
        \ min([b.thumbnail_height * 5, b.width * 4 / 5 / b.num_width])
  while (l != 3 && b.thumbnail_height * 2 > b.thumbnail_width)
        \ || (l == 3 && (b.thumbnail_height * 3 / 2
        \                     > b.thumbnail_width || b.num_height == 2))
    let b.num_height += 1
    let b.num_width = (l + b.num_height - 1) / b.num_height
    let b.thumbnail_height =
          \ min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
    let b.thumbnail_width =
          \ min([b.thumbnail_height * 6, b.width * 4 / 5 / b.num_width])
  endwhile
  while l <= b.num_width * (b.num_height - 1)
    let b.num_height -= 1
  endwhile
  let b.offset_top =
        \ (b.height - b.num_height * b.thumbnail_height) / (b.num_height + 1)
  let b.offset_left =
        \ (b.width - b.num_width * b.thumbnail_width) / (b.num_width + 1)
  let top_bottom = b.height
        \ - (b.offset_top + b.thumbnail_height) * b.num_height
  let b.margin_top = max([(top_bottom - b.offset_top) / 2, 0])
  let b.margin_bottom = max([top_bottom - b.margin_top, 0])
  return b
endfunction

function! s:thumbnail_marker(b)
  let b = a:b
  if has('conceal')
      \ && winwidth(0) > (b.num_width - 1)
      \ * (b.offset_left + b.thumbnail_width + 4) + b.offset_left + 5
    let b.marker_left_select = '  [|'
    let b.marker_right_select = '|]  '
    let b.marker_left = '  [\'
    let b.marker_right = '\]  '
    let b.marker_last = '[\\]    '
    let b.conceal = 1
  else
    let b.marker_left_select = '[|'
    let b.marker_right_select = '|]'
    let b.marker_left = '  '
    let b.marker_right = '  '
    let b.marker_last = '[\\]'
    let b.conceal = 0
  endif
  return b
endfunction

function! s:thumbnail_mapping()

  nnoremap <buffer><silent> <Plug>(thumbnail_move_left)
        \ :<C-u>call <SID>thumbnail_left()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_right)
        \ :<C-u>call <SID>thumbnail_right()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_down)
        \ :<C-u>call <SID>thumbnail_down()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_up)
        \ :<C-u>call <SID>thumbnail_up()<CR>

  nnoremap <buffer><silent> <Plug>(thumbnail_move_next)
        \ :<C-u>call <SID>thumbnail_next()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_prev)
        \ :<C-u>call <SID>thumbnail_prev()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_head)
        \ :<C-u>call <SID>thumbnail_line_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_middle)
        \ :<C-u>call <SID>thumbnail_line_middle()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_last)
        \ :<C-u>call <SID>thumbnail_line_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_head)
        \ :<C-u>call <SID>thumbnail_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_last)
        \ :<C-u>call <SID>thumbnail_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_G_last)
        \ :<C-u>call <SID>thumbnail_line_G_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_last_line_head)
        \ :<C-u>call <SID>thumbnail_last_line()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_count_line_first)
        \ :<C-u>call <SID>thumbnail_line_gg()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_count_line_last)
        \ :<C-u>call <SID>thumbnail_line_G()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_column)
        \ :<C-u>call <SID>thumbnail_column()<CR>

  nnoremap <buffer><silent> <Plug>(thumbnail_select)
        \ :<C-u>call <SID>thumbnail_select()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close)
        \ :<C-u>call <SID>thumbnail_close(0)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close_backspace)
        \ :<C-u>call <SID>thumbnail_close(1)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_exit)
        \ :<C-u>bdelete!<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_redraw)
        \ :<C-u>call <SID>update_current_thumbnail()<CR>

  nmap <buffer> h <Plug>(thumbnail_move_left)
  nmap <buffer> l <Plug>(thumbnail_move_right)
  nmap <buffer> j <Plug>(thumbnail_move_down)
  nmap <buffer> k <Plug>(thumbnail_move_up)
  nmap <buffer> <Left> h
  nmap <buffer> <BS> h
  nmap <buffer> <Right> l
  nmap <buffer> <Down> j
  nmap <buffer> <Up> k
  nmap <buffer> gh h
  nmap <buffer> gl l
  nmap <buffer> gj j
  nmap <buffer> gk k
  nmap <buffer> + j
  nmap <buffer> - k

  nmap <buffer> w <Plug>(thumbnail_move_next)
  nmap <buffer> W w
  nmap <buffer> <TAB> w
  nmap <buffer> <S-Left> w
  nmap <buffer> b <Plug>(thumbnail_move_prev)
  nmap <buffer> B b
  nmap <buffer> <S-Tab> b
  nmap <buffer> <S-Right> b
  nmap <buffer> 0 <Plug>(thumbnail_move_line_head)
  nmap <buffer> ^ 0
  nmap <buffer> g0 0
  nmap <buffer> g<Home> 0
  nmap <buffer> g^ ^
  nmap <buffer> gm <Plug>(thumbnail_move_line_middle)
  nmap <buffer> $ <Plug>(thumbnail_move_line_last)
  nmap <buffer> g$ $
  nmap <buffer> g<End> $
  nmap <buffer> gg <Plug>(thumbnail_move_count_line_first)
  nmap <buffer> <C-Home> gg
  nmap <buffer> G <Plug>(thumbnail_move_count_line_last)
  nmap <buffer> <C-End> <Plug>(thumbnail_move_G_last)
  nmap <buffer> <Bar> <Plug>(thumbnail_move_column)

  nnoremap <buffer><silent> <LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>update_select(0)<CR>
  nnoremap <buffer><silent> <LeftDrag> <LeftMouse>
        \ :<C-u>call <SID>drag_select()<CR>
  nnoremap <buffer><silent> <LeftRelease> <LeftMouse>
        \ :<C-u>call <SID>drag_select()<CR>
  nnoremap <buffer><silent> <2-LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>thumbnail_mouse_select()<CR>
  map <buffer> <ScrollWheelUp> w
  map <buffer> <ScrollWheelDown> b

  nmap <buffer> <CR> <Plug>(thumbnail_select)
  nmap <buffer> <SPACE> <CR>
  nmap <buffer> x <Plug>(thumbnail_close)
  nmap <buffer> <Del> x
  nmap <buffer> X <Plug>(thumbnail_close_backspace)
  nmap <buffer> <C-l> <Plug>(thumbnail_redraw)
  nmap <buffer> q <Plug>(thumbnail_exit)

endfunction

function! s:thumbnail_unsave(b)
  if !exists('b:thumbnail')
    return a:b
  endif
  let prev_b = b:thumbnail
  let index = prev_b.select_i * prev_b.num_width + prev_b.select_j
  let newbuf = a:b.bufs
  if len(prev_b.bufs) == len(newbuf) && index < len(newbuf)
    let flg = 1
    for i in range(len(prev_b.bufs))
      if prev_b.bufs[i].bufnr != newbuf[i].bufnr
        let flg = 0
        break
      endif
    endfor
    if flg
      let a:b.select_i = index / a:b.num_width
      let a:b.select_j = index % a:b.num_width
      return a:b
    endif
  endif
  let newbuf_nrs = map(copy(newbuf), 'v:val["bufnr"]')
  let prev_b_bufs_nrs = map(copy(prev_b.bufs), 'v:val["bufnr"]')
  let a:b.bufs = []
  for i in range(len(prev_b.bufs))
    let j = index(newbuf_nrs, prev_b.bufs[i].bufnr)
    if j != -1
      call add(a:b.bufs, newbuf[j])
    endif
  endfor
  unlet newbuf_nrs
  for i in range(len(newbuf))
    if index(prev_b_bufs_nrs, newbuf[i].bufnr) == -1
      call add(a:b.bufs, newbuf[i])
    endif
  endfor
  unlet prev_b_bufs_nrs
  if index < len(prev_b.bufs) && has_key(prev_b.bufs[index], 'bufnr')
        \ && index < len(a:b.bufs) && has_key(a:b.bufs[index], 'bufnr')
        \ && a:b.bufs[index].bufnr == prev_b.bufs[index].bufnr
    let a:b.select_i = index / a:b.num_width
    let a:b.select_j = index % a:b.num_width
    return a:b
  endif
  let direction = has_key(b:thumbnail, 'direction') ? b:thumbnail.direction : 1
  let offset = 0
  while offset < len(prev_b.bufs)
    let i = index + offset * direction
    let offset = (offset <= 0 ? 1 : 0) - offset
    if !(0 <= i && i < len(prev_b.bufs) && has_key(prev_b.bufs[i], 'bufnr'))
      continue
    endif
    let nr = prev_b.bufs[i].bufnr
    for j in range(len(a:b.bufs))
      if a:b.bufs[j].bufnr == nr
        let a:b.select_i = j / a:b.num_width
        let a:b.select_j = j % a:b.num_width
        return a:b
      endif
    endfor
  endwhile
  return a:b
endfunction

function! s:thumbnail_init(isnewtab)
  let b = s:init_buffer(a:isnewtab)
  if len(b.bufs) > 0
    let b:thumbnail = s:thumbnail_unsave(b)
    silent call s:updatethumbnail()
  endif
endfunction

function! s:thumbnail_new()
  let isnewtab = 0
  if bufname('%') != '' || &modified
    tabnew
    let isnewtab = 1
  endif
  call s:thumbnail_init(isnewtab)
  augroup Thumbnail
    autocmd!
    autocmd BufEnter,VimResized *
          \ call s:update_visible_thumbnail(expand('<abuf>'))
  augroup END
  augroup ThumbnailBuffer
    autocmd BufLeave,WinLeave <buffer>
          \ if exists('b:thumbnail') | call s:set_cursor() | endif
    autocmd BufEnter,CursorHold <buffer>
          \ call s:revive_thumbnail() |
          \ if exists('b:thumbnail') | call s:thumbnail_init(0) | endif
    autocmd WinEnter,WinLeave,VimResized <buffer>
          \ if exists('b:thumbnail') | call s:updatethumbnail() | endif
    " autocmd CursorMoved <buffer>
    "       \ silent call s:update_select(1)
  augroup END
endfunction

function! s:updatethumbnail()
  if !exists('b:thumbnail')
    return
  endif
  setlocal modifiable noreadonly
  silent % delete _
  let b = b:thumbnail
  if b.height != winheight(0) || b.width != winwidth(0)
    let b = s:init_buffer(1)
    if len(b.bufs) == 0
      return
    endif
    let b:thumbnail = s:thumbnail_unsave(b)
    let b = b:thumbnail
  endif
  let s = []
  let thumbnail_white = repeat(' ', b.thumbnail_width - 4)
  let offset_white = repeat(' ', b.offset_left)
  let line_white = repeat(' ', (b.offset_left + b.thumbnail_width)
        \ * b.num_width)
  let right_white = repeat(' ', winwidth(0) - len(line_white) - 4)
        \ . b.marker_last
  for j in range(b.margin_top)
    call add(s, line_white . right_white)
  endfor
  for i in range(b.num_height)
    for j in range(b.offset_top)
      call add(s, line_white . right_white)
    endfor
    for k in range(b.thumbnail_height)
      let ss = ''
      for j in range(b.num_width)
        let m = i * b.num_width + j
        if m < len(b.bufs) && has_key(b.bufs[m], 'contents')
              \ && k < len(b.bufs[m].contents)
          let contents = b.bufs[m].contents[k]
        else
          let contents = thumbnail_white
        endif
        if b.select_i == i && b.select_j == j
          let l = b.marker_left_select
          let r = b.marker_right_select
        else
          let l = b.marker_left
          let r = b.marker_right
        endif
        let ss .= offset_white . l . contents . r
      endfor
      call add(s, ss . right_white)
    endfor
  endfor
  for j in range(b.margin_bottom)
    call add(s, line_white . right_white)
  endfor
  silent call setline(1, s[0])
  silent call append('.', s[1:])
  unlet s
  silent call s:set_cursor()
  setlocal nomodifiable buftype=nofile noswapfile readonly nonumber
        \ bufhidden=hide nobuflisted filetype=thumbnail
        \ nofoldenable foldcolumn=0 nolist nowrap concealcursor=nvic
endfunction

function! s:set_cursor()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let offset = 0
  for j in range(b.select_j)
    let index = b.select_i * b.num_width + j
    if index < len(b.bufs) && has_key(b.bufs[index], 'firstlinelength')
      let offset += b.bufs[index].firstlinelength + b.offset_left + 4
    else
      let offset += b.offset_left + b.thumbnail_width
    endif
    if b.conceal
      let offset += 4
    endif
  endfor
  silent call cursor(b.margin_top
        \ + b.select_i * (b.offset_top + b.thumbnail_height)
        \ + b.offset_top + 1, offset + b.offset_left + 3 + b.conceal * 2) 
endfunction

function! s:search_thumbnail()
  for buf in tabpagebuflist()
    if type(getbufvar(buf, 'thumbnail')) == type({})
      return buf
    endif
  endfor
  return -1
endfunction

function! s:update_visible_thumbnail(bufnr)
  let winnr = bufwinnr(s:search_thumbnail())
  let newbuf = bufwinnr(str2nr(a:bufnr))
  let currentbuf = bufwinnr(bufnr('%'))
  if winnr != -1
    execute winnr 'wincmd w'
    if exists('b:thumbnail')
      call s:thumbnail_init(0)
    endif
    if winnr != newbuf && newbuf != -1
      call cursor(1, 1)
      execute newbuf 'wincmd w'
    elseif winnr != currentbuf && currentbuf != -1
      call cursor(1, 1)
      execute currentbuf 'wincmd w'
    endif
  endif
endfunction

function! s:update_current_thumbnail()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  call s:thumbnail_init(1)
endfunction

function! s:thumbnail_left()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_j = max([b.select_j - max([v:count, 1]), 0])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.select_j = new_j
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_right()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_j = min([b.select_j + max([v:count, 1]),
        \ b.num_width - 1,
        \ len(b.bufs) - b.select_i * b.num_width - 1])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.select_j = new_j
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_up()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_i = max([b.select_i - max([v:count, 1]), 0])
  if s:thumbnail_exists(new_i, b.select_j)
    let b.select_i = new_i
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_down()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_i = min([b.select_i + max([v:count, 1]),
        \ b.num_height - 1])
  if s:thumbnail_exists(new_i, b.select_j)
    let b.select_i = new_i
  elseif s:thumbnail_exists(new_i - 1, b.select_j)
    let b.select_i = new_i - 1
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_next()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let index = b.select_i * b.num_width + b.select_j
  let new_index = s:modulo(index + max([v:count, 1]), len(b.bufs))
  let new_i = new_index / b.num_width
  let new_j = new_index % b.num_width
  if s:thumbnail_exists(new_i, new_j)
    let b.select_i = new_i
    let b.select_j = new_j
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_prev()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let index = b.select_i * b.num_width + b.select_j
  let new_index = s:modulo(index - max([v:count, 1]), len(b.bufs))
  let new_i = new_index / b.num_width
  let new_j = new_index % b.num_width
  if s:thumbnail_exists(new_i, new_j)
    let b.select_i = new_i
    let b.select_j = new_j
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_head()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, 0)
    let b.select_j = 0
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_last()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, b.num_width - 1)
    let b.select_j = b.num_width - 1
  elseif s:thumbnail_exists(b.select_i,
        \ len(b.bufs) - b.select_i * b.num_width - 1)
    let b.select_j = len(b.bufs) - b.select_i * b.num_width - 1
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_middle()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, b.num_width / 2)
    let b.select_j = b.num_width / 2
  elseif s:thumbnail_exists(b.select_i,
        \ len(b.bufs) - b.select_i * b.num_width - 1)
    let b.select_j = len(b.bufs) - b.select_i * b.num_width - 1
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_head()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(0, 0)
    let b.select_i = 0
    let b.select_j = 0
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_last()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.num_height - 1,
        \ len(b.bufs) - (b.num_height - 1) * b.num_width - 1)
    let b.select_i = b.num_height - 1
    let b.select_j = len(b.bufs) - (b.num_height - 1) * b.num_width - 1
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_G_last()
  silent call s:thumbnail_line_G()
  silent call s:thumbnail_line_last()
endfunction

function! s:thumbnail_last_line()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.num_height - 1, 0)
    let b.select_i = b.num_height - 1
    let b.select_j = 0
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_gg()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_i = v:count != 0 ? min([max([v:count - 1, 0]), b.num_height - 1])
        \                  : 0
  if s:thumbnail_exists(new_i, 0)
    let b.select_i = new_i
    let b.select_j = 0
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_G()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_i = v:count != 0 ? min([max([v:count - 1, 0]), b.num_height - 1])
        \                  : b.num_height - 1
  if s:thumbnail_exists(new_i, 0)
    let b.select_i = new_i
    let b.select_j = 0
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_column()
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let new_j = min([max([v:count - 1, 0]),
        \ b.num_width - 1,
        \ len(b.bufs) - b.select_i * b.num_width - 1])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.select_j = new_j
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_exists(i, j)
  let b = b:thumbnail
  let k = a:i * b.num_width + a:j
  return 0 <= k && k < len(b.bufs) &&
        \ 0 <= a:i && a:i < b.num_height &&
        \ 0 <= a:j && a:j < b.num_width
endfunction

function! s:nearest_ij()
  if !exists('b:thumbnail')
    return { 'i': -1, 'j': -1 }
  endif
  let b = b:thumbnail
  let i = (line('.') - b.offset_top / 2 - 1)
        \ / (b.offset_top + b.thumbnail_height)
  if i < 0
    let i = 0
  endif
  if b.num_height <= i
    let i = b.num_height - 1
  endif
  let j = (col('.') - b.offset_left / 2 - 3)
        \ / (b.offset_left + b.thumbnail_width)
  if j < 0
    let j = 0
  endif
  if b.num_width <= j
    let j = b.num_width - 1
  endif
  if s:thumbnail_exists(i, j)
  elseif s:thumbnail_exists(i, j - 1)
    if s:thumbnail_exists(i - 1, j) &&
          \ 2 * (line('.') - i * (b.offset_top + b.thumbnail_height))
          \ < col('.') - j * (b.offset_left + b.thumbnail_width)
      let i = i - 1
    else
      let j = j - 1
    endif
  elseif s:thumbnail_exists(i - 1, j)
    let i = i - 1
  elseif s:thumbnail_exists(i - 1, j - 1)
    let i = i - 1
    let j = j - 1
  else
    return { 'i': -1, 'j': -1 }
  endif
  return { 'i': i, 'j': j }
endfunction

function! s:update_select(savepos)
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let ij = s:nearest_ij()
  if ij.i != -1 && ij.j != -1
    let b.select_i = ij.i
    let b.select_j = ij.j
    let pos = getpos('.')
    silent call s:updatethumbnail()
    if a:savepos
      silent call setpos('.', pos)
    endif
    return 0
  else
    return -1
  endif
endfunction

function! s:drag_select()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let ij = s:nearest_ij()
  if ij.i != -1 && ij.j != -1
    let index = b.select_i * b.num_width + b.select_j
    let selection = b.bufs[index]
    let new_index = ij.i * b.num_width + ij.j
    if index < new_index
      for i in range(index, new_index - 1)
        let b.bufs[i] = b.bufs[i + 1]
      endfor
      let b.bufs[new_index]  = selection
    elseif new_index < index
      for i in range(index, new_index + 1, -1)
        let b.bufs[i] = b.bufs[i - 1]
      endfor
      let b.bufs[new_index] = selection
    else
      return -1
    endif
    let b.select_i = ij.i
    let b.select_j = ij.j
    silent call s:updatethumbnail()
    return 0
  else
    return -1
  endif
endfunction

function! s:thumbnail_mouse_select()
  let r = s:update_select(0)
  if r == 0
    silent call s:thumbnail_select()
  endif
endfunction

function! s:thumbnail_select()
  if !exists('b:thumbnail')
    let prev_first_line = substitute(getline(line('.'))[col('.') - 1:],
          \ '|\].*', '', '')
    call s:revive_thumbnail()
    if exists('b:thumbnail')
      call s:updatethumbnail()
      let new_first_line = substitute(getline(line('.'))[col('.') - 1:],
            \ '|\].*', '', '')
      let l = min([len(prev_first_line), len(new_first_line)])
      if prev_first_line[:l - 1] != new_first_line[:l - 1]
        return -1
      endif
    else
      return -1
    endif
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  let bufnr = bufnr('%')
  if s:thumbnail_exists(b.select_i, b.select_j)
    let nr = b.bufs[i].bufnr
    if bufloaded(nr)
      if bufwinnr(nr) != -1
        execute bufwinnr(nr) 'wincmd w'
        execute bufnr 'bdelete!'
        return
      else
        for i in range(tabpagenr('$'))
          if index(tabpagebuflist(i + 1), nr) != -1
            execute 'tabnext' . (i + 1)
            execute bufwinnr(nr) 'wincmd w'
            execute bufnr 'bdelete!'
            return
          endif
        endfor
        execute nr 'buffer!'
      endif
    elseif buflisted(nr)
      execute nr 'buffer!'
    else
      call s:thumbnail_init(1)
    endif
  endif
endfunction

function! s:thumbnail_close(direction)
  call s:revive_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  if s:thumbnail_exists(b.select_i, b.select_j)
    let nr = b.bufs[i].bufnr
    if getbufvar(nr, '&modified')
      let name = bufname(nr)
      let message = 'The buffer ' . (name == '' ? '[No Name]' : name)
            \ . ' is modified. Force to delete the buffer? [yes/no/edit] '
      let yesno = input(message)
      while yesno !~? '^\%(y\%[es]\|n\%[o]\|e\%[dit]\)$'
        redraw
        if yesno == ''
          echo 'Canceled.'
          return
          break
        endif
        echohl WarningMsg | echomsg 'Invalid input.' | echohl None
        let yesno = input(message)
      endwhile
      if yesno =~? 'n\%[o]'
        return
      elseif yesno =~? 'e\%[dit]'
        call s:thumbnail_select()
        return
      endif
    endif
    execute nr 'bdelete!'
    if exists('b:thumbnail')
      let b:thumbnail.direction = a:direction ? -1 : 1
      silent call s:thumbnail_init(1)
    endif
  endif
endfunction

function! s:revive_thumbnail()
  if !exists('b:thumbnail')
    let b = s:init_buffer(1)
    if len(b.bufs) > 0
      let b:thumbnail = b
      let ij = s:nearest_ij()
      if ij.i != -1 && ij.j != -1
        let b:thumbnail.select_i = ij.i
        let b:thumbnail.select_j = ij.j
      endif
    endif
  endif
endfunction

" The following codes were imported from vital.vim {{{
" https://github.com/vim-jp/vital.vim (Public Domain)
function! s:truncate(str, width)
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master

  if a:str =~# '^[\x00-\x7f]*$'
    return len(a:str) < a:width ?
          \ printf('%-'.a:width.'s', a:str) : strpart(a:str, 0, a:width)
  endif

  let ret = a:str
  let width = s:wcswidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = s:wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction

function! s:truncate_smart(str, max, footer_width, separator)
  let width = s:wcswidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - s:wcswidth(a:separator) - a:footer_width
    let ret = s:strwidthpart(a:str, header_width) . a:separator
          \ . s:strwidthpart_reverse(a:str, a:footer_width)
  endif

  return s:truncate(ret, a:max)
endfunction

function! s:strwidthpart(str, width)
  if a:width <= 0
    return ''
  endif
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction

function! s:strwidthpart_reverse(str, width)
  if a:width <= 0
    return ''
  endif
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '^.')
    let ret = ret[len(char) :]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction

if v:version >= 703
  " Use builtin function.
  function! s:wcswidth(str)
    return strwidth(a:str)
  endfunction
else
  function! s:wcswidth(str)
    if a:str =~# '^[\x00-\x7f]*$'
      return strlen(a:str)
    end

    let mx_first = '^\(.\)'
    let str = a:str
    let width = 0
    while 1
      let ucs = char2nr(substitute(str, mx_first, '\1', ''))
      if ucs == 0
        break
      endif
      let width += s:_wcwidth(ucs)
      let str = substitute(str, mx_first, '', '')
    endwhile
    return width
  endfunction

  " UTF-8 only.
  function! s:_wcwidth(ucs)
    let ucs = a:ucs
    if (ucs >= 0x1100
          \  && (ucs <= 0x115f
          \  || ucs == 0x2329
          \  || ucs == 0x232a
          \  || (ucs >= 0x2e80 && ucs <= 0xa4cf
          \      && ucs != 0x303f)
          \  || (ucs >= 0xac00 && ucs <= 0xd7a3)
          \  || (ucs >= 0xf900 && ucs <= 0xfaff)
          \  || (ucs >= 0xfe30 && ucs <= 0xfe6f)
          \  || (ucs >= 0xff00 && ucs <= 0xff60)
          \  || (ucs >= 0xffe0 && ucs <= 0xffe6)
          \  || (ucs >= 0x20000 && ucs <= 0x2fffd)
          \  || (ucs >= 0x30000 && ucs <= 0x3fffd)
          \  ))
      return 2
    endif
    return 1
  endfunction
endif

function! s:modulo(n, m)
  let d = a:n * a:m < 0 ? 1 : 0
  return a:n + (-(a:n + (0 < a:m ? d : -d)) / a:m + d) * a:m
endfunction

" }}}

command! Thumbnail call s:thumbnail_new()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
