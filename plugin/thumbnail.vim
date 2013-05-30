" =============================================================================
" Filename: plugin/thumbnail.vim
" Version: 0.1
" Author: itchyny
" License: MIT License
" Last Change: 2013/05/30 18:53:45.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! s:gather_buffers()
  let bufs = []
  for i in range(1, bufnr('$'))
    if (len(bufname(i)) == 0 && (!bufexists(i) || !bufloaded(i)
          \ || !getbufvar(i, '&modified'))) || !buflisted(i)
      continue
    endif
    call add(bufs, { 'bufnr': i })
  endfor
  return bufs
endfunction

function! s:escape(dir)
  return escape(a:dir, '.$*')
endfunction

function! s:redraw_buffer_with(s)
  silent % delete _
  if len(a:s)
    call setline(1, a:s[0])
    if len(a:s) > 1
      call append('.', a:s[1:])
    endif
  endif
endfunction

function! s:new(args)
  let args = split(a:args, '\s\+')
  let isnewtab = bufname('%') != '' || &modified
  let command = 'tabnew'
  let below = ''
  for arg in args
    if arg == '-horizontal'
      let command = 'new'
    elseif arg == '-vertical'
      let command = 'vnew'
    elseif arg == '-nosplit' && !&modified
      let command = 'new | wincmd p | quit'
    elseif arg == '-newtab'
      let command = 'tabnew'
      let isnewtab = 1
    elseif arg == '-below'
      let below = 'below '
    endif
  endfor
  silent execute 'if isnewtab | ' . below . command . ' | endif'
  let b = {}
  let b.input = ''
  let b.bufs = s:gather_buffers()
  if len(b.bufs) == 0
    if isnewtab | silent bdelete! | endif
    return
  endif
  call s:arrangement(b)
  call s:setcontents(b)
  let b.marker = s:marker(b)
  call s:mapping()
  let b:thumbnail = s:unsave(b)
  call s:update()
  call s:autocmds()
endfunction

function! s:autocmds()
  augroup ThumbnailAutoUpdate
    autocmd!
    autocmd BufEnter,CursorHold,CursorHoldI,BufWritePost,VimResized *
          \ call s:update_visible_thumbnail(expand('<abuf>'))
  augroup END
  augroup ThumbnailBuffer
    autocmd BufLeave,WinLeave <buffer>
          \   if exists('b:thumbnail')
          \ |   call s:set_cursor()
          \ | endif
    autocmd BufEnter <buffer>
          \   call s:revive_thumbnail()
          \ | if exists('b:thumbnail') && !b:thumbnail.visual_mode
          \ |   call s:thumbnail_init(0)
          \ | endif
    autocmd WinEnter,WinLeave,VimResized <buffer>
          \   if exists('b:thumbnail') && !b:thumbnail.selection
          \ |   call s:update()
          \ | endif
    autocmd CursorMoved <buffer>
          \ call s:cursor_moved()
    autocmd CursorMovedI <buffer>
          \ call s:update_filter()
  augroup END
endfunction

function! s:setcontents(b)
  for buf in a:b.bufs
    let c = s:get_contents(buf.bufnr, a:b.thumbnail_width, a:b.thumbnail_height)
    call extend(buf, {
          \ 'contents': c,
          \ 'firstlinelength': len(c) > 0 ? len(c[0]) : a:b.thumbnail_width - 4
          \ })
  endfor
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
  let name = bufname
  let abbrnames = []
  call add(abbrnames, substitute(bufname, expand('~'), '~', ''))
  let updir = substitute(expand('%:p:h'), '[^/]*$', '', '')
  call add(abbrnames, substitute(bufname, s:escape(updir), '../', ''))
  let upupdir = substitute(updir, '[^/]*/$', '', '')
  call add(abbrnames, substitute(bufname, s:escape(upupdir), '../../', ''))
  for abbrname in abbrnames
    let name = len(name) > len(abbrname) ? abbrname : name
  endfor
  call insert(lines, s:truncate_smart(name == '' ? '[No Name]' : name,
        \ a:width - 4, (a:width - 4) * 3 / 5, ' .. '))
  let contents = map(lines,
        \ 's:truncate(substitute(v:val, "\t",' .
        \ string(repeat(' ', getbufvar(a:nr, '&tabstop'))) .
        \ ', "g") . "' . '", ' .  (a:width - 4) . ')')
  return contents
endfunction

function! s:arrangement(b)
  let b = a:b
  let l = len(b.bufs)
  if l == 0 | return | endif
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
  let b.offset_top = max([
        \ (b.height - b.num_height * b.thumbnail_height) / (b.num_height + 1)
        \ , 0])
  let b.offset_left = max([
        \ (b.width - b.num_width * b.thumbnail_width) / (b.num_width + 1)
        \ , 0])
  let top_bottom = b.height
        \ - (b.offset_top + b.thumbnail_height) * b.num_height
  let b.margin_top = max([(top_bottom - b.offset_top) / 2, 0])
  let b.margin_bottom = max([top_bottom - b.margin_top, 0])
  let b.select_i = 0
  let b.select_j = 0
  let b.visual_mode = 0
  let b.visual_selects = []
  let b.line_move = 0
  let b.v_count = 0
  let b.to_end = 0
  if b.offset_top + b.margin_top > 0
    let b.insert_pos = (b.offset_top + b.margin_top + 1) / 2
  else
    let b.insert_pos = 1
    let b.margin_top += 1
  endif
  return b
endfunction

function! s:marker(b)
  let b = {}
  if has('conceal')
      \ && winwidth(0) > (a:b.num_width - 1)
      \ * (a:b.offset_left + a:b.thumbnail_width + 4) + a:b.offset_left + 5
    let b.left_select = '  [|'
    let b.right_select = '|]  '
    let b.left = '  [\'
    let b.right = '\]  '
    let b.last = '    \]\]'
    let b.conceal = 1
  else
    let b.left_select = '[|'
    let b.right_select = '|]'
    let b.left = '  '
    let b.right = '  '
    let b.last = '\]\]'
    let b.conceal = 0
  endif
  return b
endfunction

function! s:mapping()

  nnoremap <buffer><silent> <Plug>(thumbnail_move_left)
        \ :<C-u>call <SID>move_left()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_right)
        \ :<C-u>call <SID>move_right()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_down)
        \ :<C-u>call <SID>move_down()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_up)
        \ :<C-u>call <SID>move_up()<CR>

  nnoremap <buffer><silent> <Plug>(thumbnail_move_next)
        \ :<C-u>call <SID>move_next()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_prev)
        \ :<C-u>call <SID>move_prev()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_head)
        \ :<C-u>call <SID>move_line_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_middle)
        \ :<C-u>call <SID>move_line_middle()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_line_last)
        \ :<C-u>call <SID>move_line_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_head)
        \ :<C-u>call <SID>move_head()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_last)
        \ :<C-u>call <SID>move_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_count_line_last_last)
        \ :<C-u>call <SID>move_line_G_last()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_last_line_head)
        \ :<C-u>call <SID>move_last_line()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_count_line_first)
        \ :<C-u>call <SID>move_line_gg()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_count_line_last)
        \ :<C-u>call <SID>move_line_G()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_move_column)
        \ :<C-u>call <SID>move_column()<CR>

  nnoremap <buffer><silent> <Plug>(thumbnail_select)
        \ :<C-u>call <SID>select()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close)
        \ :<C-u>call <SID>close(0)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_close_backspace)
        \ :<C-u>call <SID>close(1)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_exit)
        \ :<C-u>bdelete!<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_redraw)
        \ :<C-u>call <SID>update_current_thumbnail()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_nop)
        \ <Nop>
  inoremap <buffer><silent> <Plug>(thumbnail_nop)
        \ <Nop>
  nnoremap <buffer><silent> <Plug>(thumbnail_start_visual)
        \ :<C-u>call <SID>start_visual(1)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_start_line_visual)
        \ :<C-u>call <SID>start_visual(2)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_start_block_visual)
        \ :<C-u>call <SID>start_visual(3)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_start_delete)
        \ :<C-u>call <SID>start_visual(4)<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_delete_to_end)
        \ :<C-u>call <SID>delete_to_end()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_start_insert)
        \ :<C-u>call <SID>start_insert()<CR>
  inoremap <silent><buffer> <Plug>(thumbnail_start_insert)
        \ <ESC>:<C-u>call <SID>start_insert()<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_exit_insert)
        \ <ESC>:<C-u>call <SID>exit_insert()<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_select)
        \ <ESC>:<C-u>call <SID>select()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_exit_visual)
        \ :<C-u>call <SID>exit_visual()<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_delete_backward_word)
        \ <C-w>
  nnoremap <buffer><silent> <Plug>(thumbnail_update_off)
        \ :<C-u>call <SID>update_off()<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_update_off)
        \ <ESC>:<C-u>call <SID>update_off()<CR>
  nnoremap <buffer><silent> <Plug>(thumbnail_update_on)
        \ :<C-u>call <SID>update_on()<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_update_on)
        \ <ESC>:<C-u>call <SID>update_on()<CR>

  for i in ['left', 'right', 'down', 'up', 'prev', 'next']
    execute printf('imap <buffer><silent> <Plug>(thumbnail_move_%s) '
          \.'<Plug>(thumbnail_update_off)'
          \.'<Plug>(thumbnail_move_%s)'
          \.'<Plug>(thumbnail_update_on)'
          \.'<Plug>(thumbnail_start_insert)', i, i)
  endfor

  nmap <buffer> h <Plug>(thumbnail_move_left)
  nmap <buffer> l <Plug>(thumbnail_move_right)
  nmap <buffer> j <Plug>(thumbnail_move_down)
  nmap <buffer> k <Plug>(thumbnail_move_up)
  nmap <buffer> <Left> h
  nmap <buffer> <Right> l
  nmap <buffer> <Down> j
  nmap <buffer> <Up> k
  nmap <buffer> <BS> h
  nmap <buffer> gh h
  nmap <buffer> gl l
  nmap <buffer> gj j
  nmap <buffer> gk k
  nmap <buffer> g<Left> h
  nmap <buffer> g<Right> l
  nmap <buffer> g<Down> j
  nmap <buffer> g<Up> k
  nmap <buffer> + j
  nmap <buffer> - k
  nmap <buffer> <C-n> <Plug>(thumbnail_move_down)
  nmap <buffer> <C-p> <Plug>(thumbnail_move_up)
  nmap <buffer> <C-f> <Plug>(thumbnail_move_next)
  nmap <buffer> <C-b> <Plug>(thumbnail_move_prev)

  nmap <buffer> w <Plug>(thumbnail_move_next)
  nmap <buffer> W w
  nmap <buffer> e w
  nmap <buffer> E w
  nmap <buffer> <TAB> w
  nmap <buffer> <S-Right> w
  nmap <buffer> b <Plug>(thumbnail_move_prev)
  nmap <buffer> B b
  nmap <buffer> ge b
  nmap <buffer> gE b
  nmap <buffer> <S-Tab> b
  nmap <buffer> <S-Left> b
  nmap <buffer> 0 <Plug>(thumbnail_move_line_head)
  nmap <buffer> ^ 0
  nmap <buffer> g0 0
  nmap <buffer> <Home> 0
  nmap <buffer> g<Home> 0
  nmap <buffer> g^ ^
  nmap <buffer> gm <Plug>(thumbnail_move_line_middle)
  nmap <buffer> $ <Plug>(thumbnail_move_line_last)
  nmap <buffer> g$ $
  nmap <buffer> g_ $
  nmap <buffer> <End> $
  nmap <buffer> g<End> $
  nmap <buffer> gg <Plug>(thumbnail_move_count_line_first)
  nmap <buffer> <C-Home> gg
  nmap <buffer> G <Plug>(thumbnail_move_count_line_last)
  nmap <buffer> <C-End> <Plug>(thumbnail_move_count_line_last_last)
  nmap <buffer> <Bar> <Plug>(thumbnail_move_column)

  nnoremap <buffer><silent> <LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>update_select(0)<CR>
  nnoremap <buffer><silent> <LeftDrag> <LeftMouse>
        \ :<C-u>call <SID>drag_select()<CR>
  nnoremap <buffer><silent> <LeftRelease> <LeftMouse>
        \ :<C-u>call <SID>drag_select()<CR>
  nnoremap <buffer><silent> <2-LeftMouse> <LeftMouse>
        \ :<C-u>call <SID>mouse_select()<CR>
  map <buffer> <ScrollWheelUp> w
  map <buffer> <ScrollWheelDown> b

  nmap <buffer> v <Plug>(thumbnail_start_visual)
  nmap <buffer> V <Plug>(thumbnail_start_line_visual)
  nmap <buffer> <C-v> <Plug>(thumbnail_start_block_visual)
  nmap <buffer> d <Plug>(thumbnail_start_delete)
  nmap <buffer> D <Plug>(thumbnail_delete_to_end)
  nmap <buffer> <ESC> <Plug>(thumbnail_exit_visual)
  nmap <buffer> <CR> <Plug>(thumbnail_select)
  nmap <buffer> <SPACE> <CR>
  nmap <buffer> x <Plug>(thumbnail_close)
  nmap <buffer> <Del> x
  nmap <buffer> X <Plug>(thumbnail_close_backspace)
  nmap <buffer> <C-l> <Plug>(thumbnail_redraw)
  nmap <buffer> q <Plug>(thumbnail_exit)

  let nop = 'cCoOpPrRsSuUz'
  for i in range(len(nop))
    execute 'nmap <buffer> ' nop[i] ' <Plug>(thumbnail_nop)'
  endfor

  nmap <buffer> i <Plug>(thumbnail_start_insert)
  nmap <buffer> I i
  nmap <buffer> a i
  nmap <buffer> A i
  nmap <buffer> / <Plug>(thumbnail_start_insert)
  nmap <buffer> ? <Plug>(thumbnail_start_insert)
  imap <buffer> <C-n> <Plug>(thumbnail_move_down)
  imap <buffer> <C-p> <Plug>(thumbnail_move_up)
  imap <buffer> <C-f> <Plug>(thumbnail_move_next)
  imap <buffer> <C-b> <Plug>(thumbnail_move_prev)
  imap <buffer> <Down> <Plug>(thumbnail_move_down)
  imap <buffer> <Up> <Plug>(thumbnail_move_up)
  imap <buffer> <Right> <Plug>(thumbnail_move_next)
  imap <buffer> <Left> <Plug>(thumbnail_move_prev)
  imap <buffer> <ESC> <Plug>(thumbnail_exit_insert)
  imap <buffer> <C-w> <Plug>(thumbnail_delete_backward_word)
  imap <buffer> <CR> <Plug>(thumbnail_select)

endfunction

function! s:unsave(b, ...)
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
  if get(a:000, 1)
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
  endif
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
  let b = {}
  let b.input = ''
  let b.bufs = s:gather_buffers()
  if len(b.bufs) == 0
    if a:isnewtab
      silent bdelete!
    endif
    return b
  endif
  call s:arrangement(b)
  call s:setcontents(b)
  let b.marker = s:marker(b)
  call s:mapping()
  if len(b.bufs) > 0
    let b:thumbnail = s:unsave(b)
    silent call s:update()
  endif
endfunction

function! s:update()
  if !exists('b:thumbnail') || len(b:thumbnail.bufs) == 0
        \ || has_key(b:thumbnail, 'no_update')
    return
  endif
  call s:update_visual_selects()
  let b = b:thumbnail
  let after_deletion = b.visual_mode == 4
  if b.visual_mode == 4
    " Case: d{motion}, [count]d{motion}, {Visual}d, dd, [count]dd
    let r = s:close(0)
    call s:exit_visual()
    if r | return | endif
  endif
  if len(b.bufs) == 0
    return
  endif
  if b.height != winheight(0) || b.width != winwidth(0) || after_deletion
    let b = {}
    let b.input = ''
    let b.bufs = s:gather_buffers()
    if len(b.bufs) == 0
      silent bdelete!
      return
    endif
    call s:arrangement(b)
    call s:setcontents(b)
    let b.marker = s:marker(b)
    call s:mapping()
    let b:thumbnail = s:unsave(b)
  endif
  setlocal modifiable noreadonly
  let b.v_count = 0
  let b.selection = 0
  let b.to_end = 0
  let s = []
  let thumbnail_white = repeat(' ', b.thumbnail_width - 4)
  let offset_white = repeat(' ', b.offset_left)
  let line_white = repeat(' ', (b.offset_left + b.thumbnail_width)
        \ * b.num_width)
  let right_white = repeat(' ', winwidth(0) - len(line_white) - 4)
        \ . b.marker.last
  let line_white .= right_white
  call extend(s, repeat([line_white], b.margin_top))
  for i in range(b.num_height)
    call extend(s, repeat([line_white], b.offset_top))
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
        if b.visual_mode && index(b.visual_selects, m) != -1
              \ || b.select_i == i && b.select_j == j
          let l = b.marker.left_select
          let r = b.marker.right_select
        else
          let l = b.marker.left
          let r = b.marker.right
        endif
        let ss .= offset_white . l . contents . r
      endfor
      call add(s, ss . right_white)
    endfor
  endfor
  call extend(s, repeat([line_white], b.margin_bottom))
  call s:redraw_buffer_with(s)
  call setline(b.insert_pos, b.input)
  call s:set_cursor()
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
    if b.marker.conceal
      let offset += 4
    endif
  endfor
  let b.cursor_x = b.margin_top + b.select_i
        \ * (b.offset_top + b.thumbnail_height) + b.offset_top + 1
  let b.cursor_y = offset + b.offset_left + 3 + b.marker.conceal * 2
  call cursor(b.cursor_x, b.cursor_y)
endfunction

function! s:update_visible_thumbnail(bufnr)
  let nr = -1
  let newnr = str2nr(a:bufnr)
  if bufname(newnr) ==# '[Command Line]'
    return
  endif
  for buf in tabpagebuflist()
    if type(getbufvar(buf, 'thumbnail')) == type({}) && buf != newnr
      let nr = buf
      break
    endif
  endfor
  if nr == -1 | return | endif
  let winnr = bufwinnr(nr)
  let newbuf = bufwinnr(str2nr(a:bufnr))
  let currentbuf = bufwinnr(bufnr('%'))
  execute winnr 'wincmd w'
  call s:thumbnail_init(0)
  if winnr != newbuf && newbuf != -1
    call cursor(1, 1)
    execute newbuf 'wincmd w'
  elseif winnr != currentbuf && currentbuf != -1
    call cursor(1, 1)
    execute currentbuf 'wincmd w'
  endif
endfunction

function! s:update_current_thumbnail()
  try
  call s:thumbnail_init(1)
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_left()
  try
  let b = b:thumbnail
  let new_j = max([b.select_j - max([v:count, b.v_count, 1]), 0])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.prev_j = b.select_j
    let b.select_j = new_j
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_right()
  try
  let b = b:thumbnail
  let new_j = min([b.select_j + max([v:count, b.v_count, 1]),
        \ b.num_width - 1,
        \ len(b.bufs) - b.select_i * b.num_width - 1])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.prev_j = b.select_j
    let b.select_j = new_j
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_up()
  try
  let b = b:thumbnail
  let new_i = max([b.select_i - max([v:count, b.v_count, 1]), 0])
  if s:thumbnail_exists(new_i, b.select_j)
    let b.select_i = new_i
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_down(...)
  try
  let b = b:thumbnail
  let d = get(a:000, 0)
  let new_i = min([b.select_i + max([v:count, b.v_count, 1, d]),
        \ b.num_height - 1])
  if s:thumbnail_exists(new_i, b.select_j)
    let b.select_i = new_i
    let b.line_move = 1
  elseif s:thumbnail_exists(new_i - 1, b.select_j)
    let b.select_i = new_i - 1
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_next()
  try
  let b = b:thumbnail
  let index = b.select_i * b.num_width + b.select_j
  let new_index = s:modulo(index + max([v:count, b.v_count, 1]), len(b.bufs))
  let new_i = new_index / b.num_width
  let new_j = new_index % b.num_width
  if s:thumbnail_exists(new_i, new_j)
    let b.select_i = new_i
    let b.select_j = new_j
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_prev()
  try
  let b = b:thumbnail
  let index = b.select_i * b.num_width + b.select_j
  let new_index = s:modulo(index - max([v:count, b.v_count, 1]), len(b.bufs))
  let new_i = new_index / b.num_width
  let new_j = new_index % b.num_width
  if s:thumbnail_exists(new_i, new_j)
    let b.select_i = new_i
    let b.select_j = new_j
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_head()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, 0)
    let b.prev_j = b.select_j
    let b.select_j = 0
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_last()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, b.num_width - 1)
    let b.prev_j = b.select_j
    let b.select_j = b.num_width - 1
    let b.to_end = 1
    let b.line_move = 0
  elseif s:thumbnail_exists(b.select_i,
        \ len(b.bufs) - b.select_i * b.num_width - 1)
    let b.prev_j = b.select_j
    let b.select_j = len(b.bufs) - b.select_i * b.num_width - 1
    let b.to_end = 1
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_middle()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(b.select_i, b.num_width / 2)
    let b.prev_j = b.select_j
    let b.select_j = b.num_width / 2
    let b.line_move = 0
  elseif s:thumbnail_exists(b.select_i,
        \ len(b.bufs) - b.select_i * b.num_width - 1)
    let b.prev_j = b.select_j
    let b.select_j = len(b.bufs) - b.select_i * b.num_width - 1
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_head()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(0, 0)
    let b.select_i = 0
    let b.select_j = 0
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_last()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(b.num_height - 1,
        \ len(b.bufs) - (b.num_height - 1) * b.num_width - 1)
    let b.select_i = b.num_height - 1
    let b.select_j = len(b.bufs) - (b.num_height - 1) * b.num_width - 1
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_G_last()
  silent call s:move_line_G()
  silent call s:move_line_last()
endfunction

function! s:move_last_line()
  try
  let b = b:thumbnail
  if s:thumbnail_exists(b.num_height - 1, 0)
    let b.select_i = b.num_height - 1
    let b.select_j = 0
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_gg()
  try
  let b = b:thumbnail
  let new_i = v:count || b.v_count
        \   ? min([max([v:count, b.v_count, 1]) - 1, b.num_height - 1])
        \   : 0
  if s:thumbnail_exists(new_i, 0)
    let b.select_i = new_i
    let b.select_j = 0
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_line_G()
  try
  let b = b:thumbnail
  let new_i = v:count || b.v_count
        \   ? min([max([v:count, b.v_count, 1]) - 1, b.num_height - 1])
        \   : b.num_height - 1
  if s:thumbnail_exists(new_i, 0)
    let b.select_i = new_i
    let b.select_j = 0
    let b.line_move = 1
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:move_column()
  try
  let b = b:thumbnail
  let new_j = min([max([v:count, b.v_count, 1]) - 1,
        \ b.num_width - 1,
        \ len(b.bufs) - b.select_i * b.num_width - 1])
  if s:thumbnail_exists(b.select_i, new_j)
    let b.prev_j = b.select_j
    let b.select_j = new_j
    let b.line_move = 0
  endif
  call s:update()
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:thumbnail_exists(i, j)
  if !exists('b:thumbnail') " must not be revived
    return
  endif
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
    silent call s:update()
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
    silent call s:update()
    return 0
  else
    return -1
  endif
endfunction

function! s:mouse_select()
  let r = s:update_select(0)
  if r == 0
    silent call s:select()
  endif
endfunction

function! s:cursor_moved()
  if !exists('b:thumbnail') || len(b:thumbnail.bufs) == 0
    return
  endif
  let b = b:thumbnail
  let [n, l, c, o] = getpos('.')
  if has_key(b, 'cursor_x') && b.cursor_x == l && b.cursor_y == c
        \ || has_key(b, 'insert_mode') && b.insert_mode
    return
  endif
  " if c > len(getline(l)) - 4 || c == b.offset_left + 3
  if getline('.')[:c - 2] =~? '^ *$'
    " Case: :[range], d:[range]
    let new_i = min([l - 1, b.num_height - 1])
    let new_j = 0
    if s:thumbnail_exists(new_i, new_j)
      let b.select_i = new_i
      let b.select_j = new_j
      let b.line_move = 0
    endif
    if b.visual_mode < 4
      let b.visual_mode = 0
      let b.visual_selects = []
    endif
    call s:update()
  endif
endfunction

function! s:open_buffer(nr)
  let bufnr = bufnr('%')
  if bufloaded(a:nr)
    if bufwinnr(a:nr) != -1
      execute bufwinnr(a:nr) 'wincmd w'
      execute bufnr 'bdelete!'
      return
    else
      for i in range(tabpagenr('$'))
        if index(tabpagebuflist(i + 1), a:nr) != -1
          execute 'tabnext' . (i + 1)
          execute bufwinnr(a:nr) 'wincmd w'
          execute bufnr 'bdelete!'
          return
        endif
      endfor
      execute a:nr 'buffer!'
    endif
  elseif buflisted(a:nr)
    execute a:nr 'buffer!'
  else
    call s:thumbnail_init(1)
  endif
endfunction

function! s:open_buffer_tabs(nrs)
  let bufnr = bufnr('%')
  let c = 0
  let bufs = []
  let tabcount = tabpagenr('$')
  for i in range(tabpagenr('$'))
    call extend(bufs, tabpagebuflist(i + 1))
  endfor
  for nr in a:nrs
    if buflisted(nr)
      if index(bufs, nr) == -1
        execute 'tabnew'
        execute nr 'buffer!'
      endif
      let c += 1
    endif
  endfor
  if c != 0
    execute bufnr 'bdelete!'
  endif
endfunction

function! s:select(...)
  try
    call s:revive_thumbnail()
    if exists('b:thumbnail')
      call s:update()
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
  let b.selection = 1
  if b.visual_mode
    call s:open_buffer_tabs(map(copy(b.visual_selects), 'b.bufs[v:val].bufnr'))
  else
    let i = get(a:000, 0, b.select_i * b.num_width + b.select_j)
    if s:thumbnail_exists(i / b.num_width, i % b.num_width)
      call s:open_buffer(b.bufs[i].bufnr)
    endif
  endif
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:close_buffer(nr, multiple, type)
  if !exists('b:thumbnail')
    return
  endif
  if getbufvar(a:nr, '&modified')
    if a:type == 3
      execute a:nr 'bdelete!'
      return a:type
    elseif a:type == 4
      return a:type
    endif
    let name = bufname(a:nr)
    let message = printf('The buffer ' . (name == '' ? '[No Name]' : name)
          \ . ' is modified. Force to delete the buffer? [yes/no/edit%s] ',
          \ (a:multiple ? '/Yes for all/No for all' : ''))
    let yesno = input(message)
    let matcher = printf('^\(y\%%[es]\|n\%%[o]\|e\%%[dit]%s\)$',
          \ (a:multiple ? '\|Y\%[es for all]\|N\%[o for all]' : ''))
    while yesno !~# matcher
      redraw
      if yesno == ''
        echo 'Canceled.'
        return
        break
      endif
      echohl WarningMsg | echomsg 'Invalid input.' | echohl None
      let yesno = input(message)
    endwhile
    if yesno =~# '^n\%[o]'
      return 1
    elseif yesno =~# '^y\%[es]'
      execute a:nr 'bdelete!'
      return 0
    elseif yesno =~# '^e\%[dit]'
      return 2
    elseif a:multiple && yesno =~# '^Y\%[es for all]'
      execute a:nr 'bdelete!'
      return 3
    elseif a:multiple && yesno =~# '^N\%[o for all]'
      return 4
    endif
  elseif a:type != 2
    if bufexists(a:nr)
      execute a:nr 'bdelete!'
    endif
    return a:type
  endif
endfunction

function! s:close(direction)
  if !exists('b:thumbnail')
    return 0
  endif
  redraw | echo ''
  let b = b:thumbnail
  if b.visual_mode
    let r = 0
    if len(b.visual_selects) > 1 && b.visual_mode == 4
      if b.line_move == 0
        if b.visual_selects[0] > b.visual_selects[-1]
          " Case: dh, db, d^
          call remove(b.visual_selects, 0)
        elseif b.to_end == 0
          " Case: dl, dw (but not d$)
          call remove(b.visual_selects, -1)
        endif
      endif
    endif
    for i in b.visual_selects
      let r = s:close_buffer(b.bufs[i].bufnr, 1, r)
      if r == 2
        let b.visual_mode = 0
        call s:select(i)
        return 1
      endif
    endfor
    redraw | echo ''
  else
    if v:count > 1
      call s:start_visual(4)
      if a:direction
        call s:move_left()
      elseif b.select_j + v:count > b.num_width
        call s:move_line_last()
      else
        call s:move_right()
      endif
      return
    endif
    let i = b.select_i * b.num_width + b.select_j
    if s:thumbnail_exists(b.select_i, b.select_j)
      let r = s:close_buffer(b.bufs[i].bufnr, 0, 0)
      if r == 2
        call s:select(i)
        return 1
      endif
    endif
    redraw | echo ''
  endif
  if exists('b:thumbnail')
    let b:thumbnail.direction = a:direction ? -1 : 1
    if b.visual_mode != 4
      silent call s:thumbnail_init(1)
    endif
  endif
endfunction

function! s:start_visual(mode)
  try
  let b = b:thumbnail
  if b.visual_mode && a:mode == 4
    " Case: {Visual}d
    if b.visual_mode == 4
      " Case: dd
      call s:start_visual(2)
      if b.v_count
        " Case: [count]dd
        call s:move_down(b.v_count - 1)
      endif
      call s:update_visual_selects()
    endif
    let b.visual_mode = a:mode
    let b.line_move = 3 " not update visual selection
    call s:update()
    return
  endif
  let b.visual_mode = a:mode
  let b.visual_selects = []
  call extend(b.visual_selects, [ b.select_i * b.num_width + b.select_j ])
  if a:mode == 4
    let b.v_count = v:count
  else
    call s:update()
  endif
  catch
    call s:revive_thumbnail()
    call s:update()
  endtry
endfunction

function! s:delete_to_end()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.visual_mode && b.visual_mode != 4
    for i in range(b.num_height)
      let f = 0
      for j in range(min([b.num_width, len(b.bufs) - i * b.num_width]))
        let idx = i * b.num_width + j
        let c = index(b.visual_selects, idx)
        if f == 0 && c != -1
          let f = 1
        endif
        if f == 1 && c == -1
          call extend(b.visual_selects, [ idx ])
        endif
      endfor
    endfor
    let b.line_move = 1
    call s:close(0)
  else
    " Case: D
    call s:start_visual(4)
    if v:count > 1
      " Case: [count]D
      let b.select_i = min([b.select_i + v:count - 1, b.num_height - 1])
      let b.select_j = 0
    endif
    call s:move_line_last()
  endif
  call s:exit_visual()
  call s:update()
endfunction

function! s:exit_visual()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let b.visual_mode = 0
  let b.visual_selects = []
  call s:update()
endfunction

function! s:update_visual_selects()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  if b.visual_mode
    let m = b.select_i * b.num_width + b.select_j 
    if len(b.visual_selects) == 0
      call extend(b.visual_selects, [ m ])
    endif
    if b.visual_mode == 1 || (b.visual_mode == 4 && b.line_move == 0)
      let n = b.visual_selects[0]
      let b.visual_selects = []
      for i in range(n, m, 2 * (n < m) - 1)
        call extend(b.visual_selects, [ i ])
      endfor
    elseif b.visual_mode == 2 || (b.visual_mode == 4 && b.line_move == 1)
      let n = b.visual_selects[0]
      let n_i = n / b.num_width
      let b.visual_selects = []
      for i in range(n_i, b.select_i, 2 * (n_i < b.select_i) - 1)
        for j in range(b.num_width)
          if s:thumbnail_exists(i, j)
            call extend(b.visual_selects, [ i * b.num_width + j ])
          endif
        endfor
      endfor
    elseif b.visual_mode == 3
      let n = b.visual_selects[0]
      let n_i = n / b.num_width
      let n_j = n % b.num_width
      let b.visual_selects = []
      for i in range(n_i, b.select_i, 2 * (n_i < b.select_i) - 1)
        for j in range(n_j, b.select_j, 2 * (n_j < b.select_j) - 1)
          if s:thumbnail_exists(i, j)
            call extend(b.visual_selects, [ i * b.num_width + j ])
          endif
        endfor
      endfor
    endif
  endif
endfunction

function! s:start_insert()
  if !exists('b:thumbnail')
    return
  endif
  if exists(':NeoComplCacheLock')
    NeoComplCacheLock
  endif
  let b = b:thumbnail
  let b.insert_mode = 1
  setlocal modifiable noreadonly
  call cursor(b.insert_pos, 1)
  startinsert!
  if exists('*neocomplcache#skip_next_complete')
    call neocomplcache#skip_next_complete()
  endif
endfunction

function! s:update_filter()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let pos = b.insert_pos
  let input = getline(pos)
  let words = split(input, ' ')
  let white = []
  let bufs = exists('b.prev_bufs') ? b.prev_bufs : b.bufs
  for i in range(len(bufs))
    let f = 0
    for w in words
      try
        if bufname(bufs[i].bufnr) !~? w | let f = 1 | endif
      catch
        try
          if bufname(bufs[i].bufnr) !~? escape(w, '\*[]?') | let f = 1 | endif
        catch
        endtry
      endtry
      if f | break | endif
    endfor
    if f == 0
      call add(white, bufs[i])
    endif
  endfor
  let b = {}
  let b.bufs = []
  let b.input = ''
  let b.bufs = white
  let input = substitute(input, '^ *', '', '')
  let input = repeat(' ',
        \ (winwidth(0) - max([s:wcswidth(input), winwidth(0) / 8]))
        \ / 2) . input
  let b.input = input
  let b.prev_bufs = bufs
  if len(white) > 0
    call s:arrangement(b)
    call s:setcontents(b)
    let b.marker = s:marker(b)
    let b:thumbnail = s:unsave(b, 1)
    call s:update()
    call s:start_insert()
  else
    let b:thumbnail = b
    let b.select_i = 0
    let b.select_j = 0
    let b.height = winheight(0)
    let b.width = winwidth(0)
    let b.num_width = 1
    let b.num_height = 1
    let b.visual_mode = 0
    let b.visual_selects = []
    let b.line_move = 0
    let b.v_count = 0
    let b.to_end = 0
    " No match
    let s = []
    for i in range(max([(winheight(0) - 2) / 2, 0]))
      call add(s, '')
    endfor
    let mes = 'No buffer'
    call add(s, repeat(' ', (winwidth(0) - len(mes)) / 2) . mes)
    call s:redraw_buffer_with(s)
    call setline(pos, input)
    let b.insert_pos = pos
    call s:start_insert()
  endif
endfunction

function! s:exit_insert()
  if !exists('b:thumbnail')
    return
  endif
  let b = b:thumbnail
  let b.insert_mode = 0
  call s:update()
endfunction

function! s:revive_thumbnail()
  let b = {}
  let b.input = ''
  let b.bufs = s:gather_buffers()
  if len(b.bufs) == 0
    silent bdelete!
    return b
  endif
  call s:arrangement(b)
  call s:setcontents(b)
  let b.marker = s:marker(b)
  call s:mapping()
  if len(b.bufs) > 0
    let b:thumbnail = b
    let ij = s:nearest_ij()
    if ij.i != -1 && ij.j != -1
      let b:thumbnail.select_i = ij.i
      let b:thumbnail.select_j = ij.j
    endif
  endif
endfunction

function! s:update_off()
  if !exists('b:thumbnail')
    return
  endif
  let b:thumbnail.no_update = 1
endfunction

function! s:update_on()
  if !exists('b:thumbnail')
    return
  endif
  unlet b:thumbnail.no_update
endfunction

function! s:complete(arglead, cmdline, cursorpos)
  let options = [ '-horizontal', '-vertical', '-nosplit', '-newtab', '-below' ]
        " \ , '-include-filetype=', '-exclude-filetype=', '-filter-filetype=' ]
  let noconflict = [
        \ [ '-horizontal', '-vertical', '-nosplit', '-newtab' ],
        \ [ '-nosplit', '-below' ],
        \ [ '-newtab', '-below' ],
        \ ]
  if a:arglead != ''
    return sort(filter(options, 'stridx(v:val, a:arglead) == 0'))
  else
    let d = {}
    for opt in options
      let d[opt] = 0
    endfor
    for opt in options
      if d[opt] == 0
        for ncf in noconflict
          let flg = 0
          for n in ncf
            let flg = flg || stridx(a:cmdline, n) >= 0
            if flg
              break
            endif
          endfor
          if flg
            for n in ncf
              let d[n] = 1
            endfor
          endif
        endfor
      endif
    endfor
    return sort(filter(options, 'd[v:val]==0 && stridx(a:cmdline, v:val)==-1'))
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

command! -nargs=* -complete=customlist,s:complete
      \ Thumbnail call s:new(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
