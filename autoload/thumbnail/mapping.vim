" =============================================================================
" Filename: autoload/thumbnail/mapping.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/17 22:30:17.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#mapping#new() abort

  if &l:filetype ==# 'thumbnail'
    return
  endif

  let save_cpo = &cpo
  set cpo&vim

  let actions = [
        \ 'move_left', 'move_right', 'move_up', 'move_down', 'move_next', 'move_prev',
        \ 'move_line_head', 'move_line_middle', 'move_line_last', 'move_head', 'move_last', 'move_last_line_head', 'move_column',
        \ 'move_count_line_first', 'move_count_line_last', 'move_count_line_last_last',
        \ 'start_insert', 'start_insert_head', 'exit_insert',
        \ 'start_visual', 'start_line_visual', 'start_block_visual', 'exit_visual',
        \ 'start_delete', 'delete', 'delete_backspace', 'delete_to_end',
        \ 'select', 'redraw', 'exit'
        \ ]
  for action in actions
    execute printf("nnoremap <buffer><silent> <Plug>(thumbnail_%s) :<C-u>call b:thumbnail.action('%s')<CR>", action, action)
  endfor

  for dir in ['left', 'right', 'down', 'up', 'prev', 'next']
    execute printf('inoremap <buffer><silent> <Plug>(thumbnail_move_%s) '
          \.'<ESC>:call b:thumbnail.view.action("move_%s")<CR>'
          \.':call b:thumbnail.action("start_insert")<CR>', dir, dir)
  endfor
  inoremap <buffer><silent> <Plug>(thumbnail_move_cursor_left)
        \ <Left>
  inoremap <buffer><silent> <Plug>(thumbnail_move_cursor_right)
        \ <Right>

  inoremap <buffer><silent> <Plug>(thumbnail_delete_backward_word)
        \ <C-w>
  inoremap <buffer><silent> <Plug>(thumbnail_delete_backward_char)
        \ <BS>
  inoremap <buffer><silent><expr> <Plug>(thumbnail_delete_backward_line)
        \ b:thumbnail.view.get_input() =~# '^ *$' ? '' : repeat("\<BS>",
        \ len(split(substitute(b:thumbnail.view.get_input(), '^ *', '', ''), '\zs')))

  inoremap <buffer><silent> <Plug>(thumbnail_select)
        \ <ESC>:<C-u>call b:thumbnail.action('select')<CR>
  inoremap <buffer><silent> <Plug>(thumbnail_exit_insert)
        \ <ESC>:<C-u>call b:thumbnail.action('exit_insert')<CR>

  nmap <buffer> h <Plug>(thumbnail_move_left)
  nmap <buffer> l <Plug>(thumbnail_move_right)
  nmap <buffer> k <Plug>(thumbnail_move_up)
  nmap <buffer> j <Plug>(thumbnail_move_down)
  nmap <buffer> <Left> <Plug>(thumbnail_move_left)
  nmap <buffer> <Right> <Plug>(thumbnail_move_right)
  nmap <buffer> <Up> <Plug>(thumbnail_move_up)
  nmap <buffer> <Down> <Plug>(thumbnail_move_down)
  nmap <buffer> OD <Left><Plug>(thumbnail_start_insert)
  nmap <buffer> OC <Right><Plug>(thumbnail_start_insert)
  nmap <buffer> OA <Up><Plug>(thumbnail_start_insert)
  nmap <buffer> OB <Down><Plug>(thumbnail_start_insert)
  nmap <buffer> <BS> h
  nmap <buffer> gh h
  nmap <buffer> gl l
  nmap <buffer> gj j
  nmap <buffer> gk k
  nmap <buffer> g<Left> <Left>
  nmap <buffer> g<Right> <Right>
  nmap <buffer> g<Down> <Down>
  nmap <buffer> g<Up> <Up>
  nmap <buffer> <S-Down> <Down>
  nmap <buffer> <S-Up> <Up>
  nmap <buffer> + j
  nmap <buffer> - k

  nmap <buffer> w <Plug>(thumbnail_move_next)
  nmap <buffer> W w
  nmap <buffer> e w
  nmap <buffer> E w
  nmap <buffer> <TAB> w
  nmap <buffer> <S-Right> w
  nmap <buffer> <C-Right> w
  nmap <buffer> b <Plug>(thumbnail_move_prev)
  nmap <buffer> B b
  nmap <buffer> ge b
  nmap <buffer> gE b
  nmap <buffer> <S-Tab> b
  nmap <buffer> <S-Left> b
  nmap <buffer> <C-Left> b
  nmap <buffer> <C-p> <Plug>(thumbnail_move_up)
  nmap <buffer> <C-n> <Plug>(thumbnail_move_down)
  nmap <buffer> <C-f> <Plug>(thumbnail_move_next)
  nmap <buffer> <C-b> <Plug>(thumbnail_move_prev)
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

  nmap <buffer> i <Plug>(thumbnail_start_insert)
  nmap <buffer> I <Plug>(thumbnail_start_insert_head)
  nmap <buffer> a i
  nmap <buffer> A i
  nmap <buffer> / <Plug>(thumbnail_start_insert)
  nmap <buffer> v <Plug>(thumbnail_start_visual)
  nmap <buffer> V <Plug>(thumbnail_start_line_visual)
  nmap <buffer> <C-v> <Plug>(thumbnail_start_block_visual)
  if v:version > 703
    nmap <buffer><nowait> <ESC> <Plug>(thumbnail_exit_visual)
  else
    nmap <buffer> <ESC> <Plug>(thumbnail_exit_visual)
  endif
  nmap <buffer> d <Plug>(thumbnail_start_delete)
  nmap <buffer> x <Plug>(thumbnail_delete)
  nmap <buffer> <Del> x
  nmap <buffer> X <Plug>(thumbnail_delete_backspace)
  nmap <buffer> D <Plug>(thumbnail_delete_to_end)
  nmap <buffer> <CR> <Plug>(thumbnail_select)
  nmap <buffer> <SPACE> <CR>
  nmap <buffer> <C-l> <Plug>(thumbnail_redraw)
  nmap <buffer> q <Plug>(thumbnail_exit)

  nnoremap <buffer><silent> <LeftMouse> <LeftMouse>
        \ :<C-u>call b:thumbnail.action('update_select')<CR>
  nnoremap <buffer><silent> <LeftDrag> <LeftMouse>
        \ :<C-u>call b:thumbnail.action('drag')<CR>
  nnoremap <buffer><silent> <LeftRelease> <LeftMouse>
        \ :<C-u>call b:thumbnail.action('drag_release')<CR>
  nnoremap <buffer><silent> <2-LeftMouse> <LeftMouse>
        \ :<C-u>call b:thumbnail.action('mouse_select')<CR>
  map <buffer> <ScrollWheelUp> <Plug>(thumbnail_move_prev)
  map <buffer> <ScrollWheelDown> <Plug>(thumbnail_move_next)

  let nop = 'cCoOpPrRsSuUz'
  for i in range(len(nop))
    execute 'nmap <buffer> ' nop[i] ' <Nop>'
  endfor

  imap <buffer> <C-p> <Plug>(thumbnail_move_up)
  imap <buffer> <C-n> <Plug>(thumbnail_move_down)
  imap <buffer> <C-f> <Plug>(thumbnail_move_next)
  imap <buffer> <C-b> <Plug>(thumbnail_move_prev)
  imap <buffer> <Up> <Plug>(thumbnail_move_up)
  imap <buffer> <Down> <Plug>(thumbnail_move_down)
  imap <buffer> <Right> <Plug>(thumbnail_move_right)
  imap <buffer> <Left> <Plug>(thumbnail_move_left)
  imap <buffer> <C-w> <Plug>(thumbnail_delete_backward_word)
  imap <buffer> <BS> <Plug>(thumbnail_delete_backward_char)
  imap <buffer> <C-h> <Plug>(thumbnail_delete_backward_char)
  imap <buffer> <C-u> <Plug>(thumbnail_delete_backward_line)
  imap <buffer> <CR> <Plug>(thumbnail_select)
  imap <buffer> <ESC> <Plug>(thumbnail_exit_insert)

  let &cpo = save_cpo

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
