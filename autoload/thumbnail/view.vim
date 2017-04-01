" =============================================================================
" Filename: autoload/thumbnail/view.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/04/01 12:06:55.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#view#new() abort
  return deepcopy(s:self)
endfunction

let s:self = {}

function! s:self.prepare(len, index) dict abort
  let self.len = a:len
  let self.input = ''
  let self.winheight = winheight(0)
  let self.winwidth = winwidth(0)
  let self.height = 1
  let self.width = a:len
  let self.thumbnail_height = min([self.winheight * 4 / 5 / self.height, self.winheight * 3 / 5])
  let self.thumbnail_width = min([self.thumbnail_height * 5, self.winwidth * 4 / 5 / self.width])
  if a:len > 0
    while (a:len != 3 && self.thumbnail_height * 2 > self.thumbnail_width) || (a:len == 3 && (self.thumbnail_height * 3 / 2 > self.thumbnail_width || self.height == 2))
      let self.height += 1
      let self.width = (a:len + self.height - 1) / self.height
      let self.thumbnail_height = min([self.winheight * 4 / 5 / self.height, self.winheight * 3 / 5])
      let self.thumbnail_width = min([self.thumbnail_height * 6, self.winwidth * 4 / 5 / self.width])
    endwhile
    while a:len <= self.width * (self.height - 1)
      let self.height -= 1
    endwhile
  endif
  let self.offset_top = max([(self.winheight - self.height * self.thumbnail_height) / (self.height + 1), 0])
  let self.offset_left = max([(self.winwidth - self.width * self.thumbnail_width) / (self.width + 1), 0])
  let top_bottom = self.winheight - (self.offset_top + self.thumbnail_height) * self.height
  let self.margin_top = max([(top_bottom - self.offset_top) / 2, 0])
  let self.margin_bottom = max([top_bottom - self.margin_top, 0])
  let self.index = a:index
  let self.insert_mode = 0
  let self.visual_mode = ''
  let self.visual_selections = []
  let self.line_move = 0
  let self.v_count = 0
  let self.to_head = 0
  let self.to_end = 0
  let self.delete_to_end = 0
  let self.save_cursor = 0
  if self.offset_top + self.margin_top > 0
    let self.insert_pos = (self.offset_top + self.margin_top + 1) / 2
  else
    let self.insert_pos = 1
    let self.margin_top += 1
  endif
  if has_key(self, 'marker')
    return
  endif
  let self.marker = {}
  if has('conceal') && self.winwidth >
        \ (self.width - 1) * (self.offset_left + self.thumbnail_width + 4) + self.offset_left + 5
    let self.marker.left_select = '  [|'
    let self.marker.right_select = '|]  '
    let self.marker.left_visual_select = '  [^'
    let self.marker.right_visual_select = '^]  '
    let self.marker.left = '  [\'
    let self.marker.right = '\]  '
    let self.marker.last = '    \]\]'
    let self.marker.conceal = 1
  else
    let self.marker.left_select = '[|'
    let self.marker.right_select = '|]'
    let self.marker.left_visual_select = '[^'
    let self.marker.right_visual_select = '^]'
    let self.marker.left = '  '
    let self.marker.right = '  '
    let self.marker.last = '\]\]'
    let self.marker.conceal = 0
  endif
endfunction

function! s:self.get_input() dict abort
  return substitute(getline(self.insert_pos), '^ *', '', '')
endfunction

function! s:self.set_input(input) dict abort
  let self.input = a:input
endfunction

function! s:self.redraw(buffers) dict abort
  call self.update_visual_selections()
  let s = []
  if self.len > 0
    let thumbnail_white = repeat(' ', self.thumbnail_width - 4)
    let offset_white = repeat(' ', self.offset_left)
    let line_white = repeat(' ', (self.offset_left + self.thumbnail_width) * self.width)
    let right_white = repeat(' ', self.winwidth - len(line_white) - 4) . self.marker.last
    let line_white .= right_white
    let line_white_repeat = repeat([line_white], self.winheight)
    call extend(s, repeat([line_white], self.margin_top))
    for i in range(self.height)
      call extend(s, line_white_repeat[:self.offset_top - 1])
      for k in range(self.thumbnail_height)
        let ss = ''
        for j in range(self.width)
          let m = i * self.width + j
          if m < len(a:buffers)
            let buffer_contents = a:buffers[m].get_contents(self.thumbnail_width, self.thumbnail_height)
            let contents = get(buffer_contents, k, thumbnail_white)
          else
            let contents = thumbnail_white
          endif
          if m == self.index
            let [l, r] = [self.marker.left_select, self.marker.right_select]
          elseif !empty(self.visual_mode) && index(self.visual_selections, m) != -1
            let [l, r] = [self.marker.left_visual_select, self.marker.right_visual_select]
          else
            let [l, r] = [self.marker.left, self.marker.right]
          endif
          if has('conceal')
            let contents = substitute(contents, '\[\zs\ze[|^\\]\|[|^\\]\zs\ze\]', '\t', 'g')
          endif
          let ss .= offset_white . l . contents . r
        endfor
        call add(s, ss . right_white)
      endfor
    endfor
    call extend(s, repeat([line_white], self.margin_bottom))
  else
    for i in range(max([(self.winheight - 2) / 2, 0]))
      call add(s, '')
    endfor
    let no_buffer = 'No buffer'
    call add(s, repeat(' ', (self.winwidth - len(no_buffer)) / 2) . no_buffer)
  endif
  let pos = getpos('.')
  call thumbnail#setlocal#modifiable()
  silent % delete _
  call setline(1, s)
  call setline(self.insert_pos, self.input)
  if self.save_cursor
    call setpos('.', pos)
  elseif self.index >= 0
    call self.set_cursor(a:buffers)
  endif
  call thumbnail#setlocal#nomodifiable()
endfunction

function! s:self.set_cursor(buffers) dict abort
  let offset = 0
  for index in range(self.index / self.width * self.width, self.index - 1)
    if index < len(a:buffers)
      let buffer_contents = a:buffers[index].get_contents(self.thumbnail_width, self.thumbnail_height)
      let offset += len(buffer_contents[0]) + 4 + self.offset_left
    else
      let offset += self.offset_left + self.thumbnail_width
    endif
    let offset += self.marker.conceal ? 4 : 0
  endfor
  let self.cursor_x = self.margin_top + self.index / self.width
        \ * (self.offset_top + self.thumbnail_height) + self.offset_top + 1
  let self.cursor_y = offset + self.offset_left + 3 + self.marker.conceal * 2
  call cursor(self.cursor_x, self.cursor_y)
endfunction

function! s:self.action(action) dict abort
  if has_key(self, a:action)
    return self[a:action]()
  else
    echo 'no action named: ' . a:action
    return 1
  endif
endfunction

function! s:self.move_left() dict abort
  let self.index -= min([max([v:count, self.v_count, 1]), self.index % self.width])
  let self.line_move = 0
  let self.to_head = 1
  let self.to_end = 0
endfunction

function! s:self.move_right() dict abort
  let self.index += min([max([v:count, self.v_count, 1]), self.width - self.index % self.width - 1, self.len - self.index - 1])
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_up() dict abort
  let self.index -= min([max([v:count, self.v_count, 1]), self.index / self.width]) * self.width
  let self.line_move = 1
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_down(...) dict abort " a:1: how many count we should move down
  let self.index += min([get(a:000, 0, max([v:count, self.v_count, 1])), (self.len - self.index - 1) / self.width]) * self.width
  let self.line_move = 1
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_next() dict abort
  let self.index = s:modulo(self.index + max([v:count, self.v_count, 1]), self.len)
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_prev() dict abort
  let self.index = s:modulo(self.index - max([v:count, self.v_count, 1]), self.len)
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_line_head() dict abort
  let self.index = self.index / self.width * self.width
  let self.line_move = 0
  let self.to_head = 1
  let self.to_end = 0
endfunction

function! s:self.move_line_middle() dict abort
  let self.index = min([self.index / self.width * self.width + self.width / 2, self.len - 1])
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_line_last() dict abort
  let self.index = min([self.index / self.width * self.width + self.width - 1, self.len - 1])
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 1
endfunction

function! s:self.move_head() dict abort
  let self.index = 0
  let self.line_move = 1
  let self.to_head = 1
  let self.to_end = 0
endfunction

function! s:self.move_last() dict abort
  let self.index = self.len - 1
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 1
endfunction

function! s:self.move_last_line_head() dict abort
  let self.index = (self.len - 1) / self.width * self.width
  let self.line_move = 1
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_column() dict abort
  let self.index = min([self.index / self.width * self.width + min([max([v:count, self.v_count, 1]) - 1, self.width - 1]), self.len - 1])
  let self.line_move = 0
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_count_line_first() dict abort
  let self.index = (v:count || self.v_count ? min([max([v:count, self.v_count, 1]) - 1, self.height - 1]) : 0) * self.width
  let self.line_move = 1
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_count_line_last() dict abort
  let self.index = (v:count || self.v_count ? min([max([v:count, self.v_count, 1]) - 1, self.height - 1]) : self.height - 1) * self.width
  let self.line_move = 1
  let self.to_head = 0
  let self.to_end = 0
endfunction

function! s:self.move_count_line_last_last() dict abort
  call self.move_count_line_last()
  call self.move_line_last()
endfunction

function! s:modulo(n, m) abort
  let d = a:n * a:m < 0 ? 1 : 0
  return a:n + (-(a:n + (0 < a:m ? d : -d)) / a:m + d) * a:m
endfunction

function! s:self.start_insert() dict abort
  let self.insert_mode = 1
  call thumbnail#setlocal#modifiable()
  call setline(self.insert_pos, self.input)
  call cursor(self.insert_pos, 1)
  startinsert!
  return 1
endfunction

function! s:self.start_insert_head() dict abort
  let self.insert_mode = 1
  call thumbnail#setlocal#modifiable()
  call setline(self.insert_pos, self.input)
  call cursor(self.insert_pos, 0)
  startinsert
  return 1
endfunction

function! s:self.exit_insert() dict abort
  let self.insert_mode = 0
  call thumbnail#setlocal#nomodifiable()
endfunction

function! s:self.start_visual() dict abort
  call self.start_visual_mode('v')
endfunction

function! s:self.start_line_visual() dict abort
  call self.start_visual_mode('V')
endfunction

function! s:self.start_block_visual() dict abort
  call self.start_visual_mode("\<C-v>")
endfunction

function! s:self.start_delete() dict abort
  call self.start_visual_mode('d')
  let self.v_count = v:count
  return 1
endfunction

function! s:self.start_visual_mode(mode) dict abort
  if self.visual_mode == a:mode " vv, VV, <C-v><C-v>
    call self.exit_visual()
  elseif empty(self.visual_mode) " v, V, <C-v>
    let self.visual_mode = a:mode
  else  " vV, v<C-v>, Vv, V<C-v>, <C-v>v, <C-v>V
    let self.visual_mode = a:mode
  endif
  if empty(self.visual_selections)
    call add(self.visual_selections, self.index)
  endif
endfunction

function! s:self.delete_mode() dict abort
  return self.visual_mode ==# 'd'
endfunction

function! s:self.update_visual_selections() dict abort
  if empty(self.visual_mode)
    return
  endif
  let start_index = self.visual_selections[0]
  let indices = []
  if self.visual_mode ==# 'v' || (self.visual_mode ==# 'd' && self.line_move == 0)
    let indices = range(start_index, self.index, start_index < self.index ? 1 : -1)
  elseif self.visual_mode ==# 'V' || (self.visual_mode ==# 'd' && self.line_move == 1)
    for i in range(start_index / self.width, self.index / self.width, start_index / self.width < self.index / self.width ? 1 : -1)
      for j in range(self.width)
        call add(indices, i * self.width + j)
      endfor
    endfor
  elseif self.visual_mode ==# "\<C-v>"
    for i in range(start_index / self.width, self.index / self.width, start_index / self.width < self.index / self.width ? 1 : -1)
      for j in range(self.delete_to_end ? min([start_index % self.width, self.index % self.width]) : start_index % self.width,
            \ self.delete_to_end ? self.width - 1 : self.index % self.width,
            \ self.delete_to_end || start_index % self.width < self.index % self.width ? 1 : -1)
        call add(indices, i * self.width + j)
      endfor
    endfor
  endif
  let self.visual_selections = [start_index]
  for index in indices
    if 0 <= index && index < self.len && index != start_index
      call add(self.visual_selections, index)
    endif
  endfor
endfunction

function! s:self.exit_visual() dict abort
  let self.visual_mode = ''
  let self.visual_selections = []
endfunction

function! s:self.delete_indices(...) dict abort " a:1: direction of deletion motion (x or X)
  if !empty(self.visual_selections)
    if !self.line_move
      if self.visual_selections[0] > self.visual_selections[-1] || self.to_head
        call remove(self.visual_selections, 0) " dh, db, d^
      elseif self.visual_selections[0] < self.visual_selections[-1] && !self.to_end
        call remove(self.visual_selections, -1) " dl, dw (not d$)
      endif
    endif
    return self.visual_selections
  elseif get(a:000, 0) == 0
    return [self.index]
  elseif self.index % self.width >= 1
    return [self.index - 1]
  endif
  return []
endfunction

function! s:self.cursor_moved() dict abort
  let [bufnum, lnum, col, offset] = getpos('.')
  if self.cursor_x == lnum && self.cursor_y == col || self.insert_mode || self.save_cursor
    return 1
  endif
  if getline('.')[:col - 2] =~? '^ *$'
    " :[range], d:[range]
    let index = min([lnum - 1, self.height - 1]) * self.width
    if 0 <= index && index < self.len
      let self.index = index
      let self.line_move = 0
    endif
    " TODO
    " if self.visual_mode < 4
    "   let self.visual_mode = 0
    "   let self.visual_selections = []
    " endif
    " call s:update()
  else
    return 1
  endif
endfunction

function! s:self.update_select() dict abort
  let index = self.nearest_index()
  if index >= 0
    let self.index = index
  else
    return 1
  endif
endfunction

function! s:self.drag_release() dict abort
  let self.save_cursor = 0
endfunction

function! s:self.nearest_index() dict abort
  let l = max([min([(line('.') - self.offset_top / 2 - 1)
        \ / (self.offset_top + self.thumbnail_height), self.height - 1]), 0])
  let c = max([min([(col('.') - self.offset_left / 2 - 3)
        \ / (self.offset_left + self.thumbnail_width), self.width - 1]), 0])
  let index = l * self.width + c
  if !(0 <= index && index < self.len)
    if 0 <= index - 1 && index - 1 < self.len
      if 0 <= index - self.width && index - self.width < self.len &&
            \ 2 * (line('.') - l * (self.offset_top + self.thumbnail_height))
            \ < col('.') - c * (self.offset_left + self.thumbnail_width)
        let index -= self.width
      else
        let index -= 1
      endif
    elseif 0 <= index - self.width && index - self.width < self.len
      let index -= self.width
    elseif 0 <= index - (self.width + 1) && index - (self.width + 1) < self.len
      let index -= self.width + 1
    else
      return -1
    endif
  endif
  return index
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
