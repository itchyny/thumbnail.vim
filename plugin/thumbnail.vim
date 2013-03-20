" =============================================================================
" Filename: plugin/thumbnail.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/03/20 20:41:53.
" =============================================================================

let s:Prelude = vital#of('thumbnail.vim').import('Prelude')

function! s:init_buffer(isnewtab)
  let b = {}
  let b.height = winheight(0)
  let b.width = winwidth(0)
  let b.bufs = []
  for i in range(1, bufnr('$'))
    let name = bufname(i)
    if len(name) == 0 || !buflisted(i)
      continue
    endif
    call add(b.bufs, {
          \ 'bufnr': i,
          \ 'bufname': name,
          \ 'loaded': bufloaded(i) && bufexists(i) && name != '',
          \ })
  endfor
  if len(b.bufs) == 0
    if a:isnewtab
      silent bdelete!
    endif
    return b
  endif
  let b.bufleft_select = '[|'
  let b.bufright_select = '|]'
  let b.bufleft = '[\'
  let b.bufright = '\]'
  let b.num_height = 1
  let b.num_width = len(b.bufs)
  let b.thumbnail_height =
        \ min([b.height * 4 / 5 / b.num_height, b.height * 3 / 5])
  let b.thumbnail_width =
        \ min([b.thumbnail_height * 5, b.width * 4 / 5 / b.num_width])
  while b.thumbnail_height * 2 > b.thumbnail_width && b.num_height < 10
    let b.num_height += 1
    let b.num_width = (len(b.bufs) + b.num_height - 1) / b.num_height
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
    let contents = map(lines,
          \ 's:Prelude.truncate(substitute(v:val, "\t",' .
          \ string(repeat(' ', getbufvar(buf.bufnr, '&tabstop'))) .
          \ ', "g") . "' . '", ' .  (b.thumbnail_width - 4) . ')')
    call extend(buf, {
          \ 'contents': contents,
          \ 'firstlinelength': len(contents) > 0 ? len(contents[0])
          \                                      : b.thumbnail_width - 4
          \ })
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

  nnoremap <buffer><silent> <Plug>(thumbnail_move_next)
        \ :<C-u>call <SID>thumbnail_next()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_prev)
        \ :<C-u>call <SID>thumbnail_prev()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_head)
        \ :<C-u>call <SID>thumbnail_line_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_last)
        \ :<C-u>call <SID>thumbnail_line_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_head)
        \ :<C-u>call <SID>thumbnail_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_last)
        \ :<C-u>call <SID>thumbnail_last()<CR>

  nnoremap <buffer><silent> <Plug>(thumbnail_select)
        \ :<C-u>call <SID>thumbnail_select()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close)
        \ :<C-u>call <SID>thumbnail_close()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_exit)
        \ :<C-u>bdelete!<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_redraw)
        \ :<C-u>call <SID>update_current_thumbnail()<CR>

  nmap <buffer> h <Plug>(thumbnail_move_left)
  nmap <buffer> l <Plug>(thumbnail_move_right)
  nmap <buffer> j <Plug>(thumbnail_move_down)
  nmap <buffer> k <Plug>(thumbnail_move_up)

  nmap <buffer> w <Plug>(thumbnail_move_next)
  nmap <buffer> W w
  nmap <buffer> <TAB> w
  nnoremap <buffer><silent> <LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>update_select()<CR>
  nnoremap <buffer><silent> <2-LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>thumbnail_mouse_select()<CR>
  map <buffer> <ScrollWheelUp> w
  nmap <buffer> b <Plug>(thumbnail_move_prev)
  nmap <buffer> B b
  nmap <buffer> <S-Tab> b
  map <buffer> <ScrollWheelDown> b
  nmap <buffer> 0 <Plug>(thumbnail_move_line_head)
  nmap <buffer> ^ 0
  nmap <buffer> $ <Plug>(thumbnail_move_line_last)
  nmap <buffer> gg <Plug>(thumbnail_move_head)
  nmap <buffer> G <Plug>(thumbnail_move_last)

  nmap <buffer> <Left> <Plug>(thumbnail_move_left)
  nmap <buffer> <Right> <Plug>(thumbnail_move_right)
  nmap <buffer> <Down> <Plug>(thumbnail_move_down)
  nmap <buffer> <Up> <Plug>(thumbnail_move_up)

  nmap <buffer> <CR> <Plug>(thumbnail_select)
  nmap <buffer> <SPACE> <CR>
  nmap <buffer> x <Plug>(thumbnail_close)
  nmap <buffer> q <Plug>(thumbnail_exit)
  nmap <buffer> <C-l> <Plug>(thumbnail_redraw)

endfunction

function! s:thumbnail_init(isnewtab, cursor)
  let b = s:init_buffer(a:isnewtab)
  if len(b.bufs) > 0
    let b:thumbnail = b
    silent call s:updatethumbnail()
    if a:cursor
      call s:set_cursor()
    else
      call cursor(1, 1)
    endif
  endif
endfunction

function! s:thumbnail_new()
  let isnewtab = 0
  if bufname('%') != '' || &modified
    tabnew
    let isnewtab = 1
  endif
  call s:thumbnail_init(isnewtab, 1)
  augroup Thumbnail
    autocmd!
    autocmd BufEnter,VimResized *
          \ call s:update_visible_thumbnail(expand('<abuf>'))
  augroup END
  augroup ThumbnailBuffer
    autocmd BufEnter,VimResized <buffer>
          \ if exists('b:thumbnail') | call s:thumbnail_init(0, 0) | endif
    autocmd BufLeave,WinLeave <buffer>
          \ silent call cursor(1, 1)
  augroup END
endfunction

function! s:updatethumbnail()
  if !exists('b:thumbnail')
    return
  endif
  setlocal modifiable noreadonly
  silent % delete _
  let b = b:thumbnail
  let s = []
  let thumbnail_white = repeat(' ', b.thumbnail_width - 4)
  let offset_white = repeat(' ', b.offset_left)
  let line_white = repeat(' ', (b.offset_left + b.thumbnail_width)
        \ * b.num_width)
  let right_white = repeat(' ', winwidth(0) - len(line_white))
        \ . b.bufright . b.bufright
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
          let l = b.bufleft_select
          let r = b.bufright_select
        else
          let l = b.bufleft
          let r = b.bufright
        endif
        let ss .= offset_white . l . contents . r
      endfor
      call add(s, ss . right_white)
    endfor
  endfor
  for j in range(b.offset_top + 1)
    call add(s, line_white . right_white)
  endfor
  call append(0, s)
  silent call s:set_cursor()
  setlocal nomodifiable buftype=nofile noswapfile readonly nonumber
        \ bufhidden=hide nobuflisted filetype=thumbnail
        \ nofoldenable foldcolumn=0 nolist nowrap
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
  endfor
  silent call cursor(b.select_i * (b.offset_top + b.thumbnail_height)
        \ + b.offset_top + 1, offset + b.offset_left + 3)
endfunction

function! s:search_thumbnail()
  for buf in tabpagebuflist()
    if type(getbufvar(buf, 'thumbnail')) == type({}) && buf != bufnr('%')
      return buf
    endif
  endfor
  return -1
endfunction

function! s:update_visible_thumbnail(bufnr)
  let winnr = bufwinnr(s:search_thumbnail())
  let newbuf = bufwinnr(str2nr(a:bufnr))
  if winnr != -1 && newbuf != -1
    execute winnr 'wincmd w'
    if exists('b:thumbnail')
      call s:thumbnail_init(0, 0)
    endif
    if winnr != newbuf
      silent call cursor(1, 1)
      execute newbuf 'wincmd w'
    endif
  endif
endfunction

function! s:update_current_thumbnail()
  if !exists('b:thumbnail')
    return
  endif
  call s:thumbnail_init(1, 1)
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
    if s:thumbnail_exists(b.select_i, b.select_j + 1)
      let b.select_j += 1
      call s:updatethumbnail()
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
    if s:thumbnail_exists(b.select_i + 1, b.select_j)
      let b.select_i += 1
      call s:updatethumbnail()
    endif
  endif
endfunction

function! s:thumbnail_next()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_j + 1 < b.num_width
    if s:thumbnail_exists(b.select_i, b.select_j + 1)
      let b.select_j += 1
    elseif s:thumbnail_exists(0, 0)
      let b.select_i = 0
      let b.select_j = 0
    else
      return
    endif
  elseif s:thumbnail_exists(b.select_i + 1, 0)
    let b.select_i += 1
    let b.select_j = 0
  elseif s:thumbnail_exists(0, 0)
    let b.select_i = 0
    let b.select_j = 0
  else
    return
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_prev()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.select_j > 0
    let b.select_j -= 1
  elseif s:thumbnail_exists(b.select_i - 1, b.num_width - 1)
    let b.select_i -= 1
    let b.select_j = b.num_width - 1
  elseif s:thumbnail_exists(b.num_height - 1,
        \ len(b.bufs) - (b.num_height - 1) * b.num_width - 1)
    let b.select_i = b.num_height - 1
    let b.select_j = len(b.bufs) - (b.num_height - 1) * b.num_width - 1
  else
    return
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_head()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, 0)
    let b.select_j = 0
  else
    return
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_line_last()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, b.num_width - 1)
    let b.select_j = b.num_width - 1
  elseif s:thumbnail_exists(b.select_i,
        \ len(b.bufs) - b.select_i * b.num_width - 1)
    let b.select_j = len(b.bufs) - b.select_i * b.num_width - 1
  else
    return
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_head()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(0, 0)
    let b.select_i = 0
    let b.select_j = 0
  else
    return
  endif
  call s:updatethumbnail()
endfunction

function! s:thumbnail_last()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if s:thumbnail_exists(b.num_height - 1,
        \ len(b.bufs) - (b.num_height - 1) * b.num_width - 1)
    let b.select_i = b.num_height - 1
    let b.select_j = len(b.bufs) - (b.num_height - 1) * b.num_width - 1
  else
    return
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

function! s:update_select()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = (line('.') - b.offset_top / 2 - 1)
        \ / (b.offset_top + b.thumbnail_height)
  if i < 0 | let i = 0 | endif
  if b.num_height <= i | let i = b.num_height - 1 | endif
  let j = (col('.') - b.offset_left / 2 - 3)
        \ / (b.offset_left + b.thumbnail_width)
  if j < 0 | let j = 0 | endif
  if b.num_width <= j | let j = b.num_width - 1 | endif
  if s:thumbnail_exists(i, j)
    let b.select_i = i
    let b.select_j = j
  elseif s:thumbnail_exists(i, j - 1)
    let b.select_i = i
    let b.select_j = j - 1
  elseif s:thumbnail_exists(i - 1, j)
    let b.select_i = i - 1
    let b.select_j = j
  elseif s:thumbnail_exists(i - 1, j - 1)
    let b.select_i = i - 1
    let b.select_j = j - 1
  else
    return -1
  endif
  silent call s:updatethumbnail()
  return 0
endfunction

function! s:thumbnail_mouse_select()
  let r = s:update_select()
  if r == 0
    silent call s:thumbnail_select()
  endif
endfunction

function! s:thumbnail_select()
  if !exists('b:thumbnail')
    return -1
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  let bufnr = bufnr('%')
  if s:thumbnail_exists(b.select_i, b.select_j)
    let buf = b.bufs[i].bufname
    let num = bufnr(escape(buf, '*[]?{}, '))
    if num > -1
      if bufloaded(num)
        if bufwinnr(num) != -1
          execute bufwinnr(num) 'wincmd w'
          execute bufnr 'bdelete!'
          return
        else
          for i in range(tabpagenr('$'))
            if index(tabpagebuflist(i + 1), num) != -1
              execute 'tabnext' . (i + 1)
              execute bufwinnr(bufnr(escape(buf, '*[]?{}, '))) 'wincmd w'
              execute bufnr 'bdelete!'
              return
            endif
          endfor
          execute num 'buffer!'
        endif
      else
        execute num 'buffer!'
      endif
    endif
  endif
endfunction

function! s:thumbnail_close()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let i = b.select_i * b.num_width + b.select_j
  if s:thumbnail_exists(b.select_i, b.select_j)
    let buf = b.bufs[i].bufname
    let num = bufnr(escape(buf, '*[]?{}, '))
    if num > -1
      silent execute num 'bdelete!'
      silent call s:thumbnail_init(1, 1)
    endif
  endif
endfunction

command! Thumbnail call s:thumbnail_new()

