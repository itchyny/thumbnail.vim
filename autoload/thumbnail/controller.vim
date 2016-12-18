" =============================================================================
" Filename: autoload/thumbnail/controller.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/18 09:45:43.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#controller#new(ftconfig) abort
  let self = deepcopy(s:self)
  let self.buffers = thumbnail#buffers#new(a:ftconfig)
  let self.view = thumbnail#view#new()
  return self
endfunction

let s:self = {}

function! s:self.update() dict abort
  call self.gather()
  call self.prepare()
  call self.redraw()
endfunction

function! s:self.prepare() dict abort
  call self.view.prepare(self.buffers.len(), 0)
  call thumbnail#mapping#new()
  call thumbnail#autocmd#new()
  call thumbnail#setlocal#new()
endfunction

function! s:self.action(action) dict abort
  if has_key(self, a:action)
    if self[a:action]() == 0
      call self.redraw()
    endif
  elseif self.view.action(a:action) == 0
    if self.view.delete_mode() " d{motion}, [count]d{motion}
      if self.close_buffers(1)
        return
      endif
    endif
    call self.redraw()
  endif
endfunction

function! s:self.close_buffers(redraw, ...) dict abort " a:1: direction of deletion motion (x or X)
  if a:redraw
    call self.redraw()
    redraw
    sleep 100m
  endif
  let selections = add(copy(self.view.visual_selections), self.view.index)
  let indices = filter([self.view.index, self.view.index + 1, max(selections), max(selections) + 1, min(selections) - 1], '0 <= v:val && v:val < self.view.len')
  let bufnrs = map(indices, 'self.buffers.get(v:val).bufnr')
  if self.buffers.close_buffers(self.view.delete_indices(get(a:000, 0)))
    return 1
  endif
  call self.buffers.gather()
  if self.buffers.len() == 0
    call self.exit()
    return 1
  endif
  call self.view.prepare(self.buffers.len(), get(filter(map(bufnrs, 'self.buffers.index_of(v:val)'), '0 <= v:val'), 0))
endfunction

function! s:self.select() dict abort
  if !empty(self.view.visual_mode)
    return self.buffers.open_buffer_tabs(map(copy(self.view.visual_selections), 'self.buffers.get(v:val).bufnr'))
  elseif self.buffers.has(self.view.index)
    return self.buffers.open(self.buffers.get(self.view.index).bufnr)
  endif
endfunction

function! s:self.start_delete() dict abort
  if self.view.delete_mode() " dd, [count]dd, d[count]d
    call self.view.start_line_visual()
    call self.view.move_line_head()
    call self.view.move_down(max([v:count - 1, self.view.v_count - 1, 0]))
    return self.close_buffers(1)
  elseif empty(self.view.visual_mode) " d, [count]d
    return self.view.start_delete()
  else " {Visual}d
    let self.view.line_move = 1
    return self.close_buffers(1)
  endif
endfunction

function! s:self.delete() dict abort
  return self._delete(0) " x, [count]x
endfunction

function! s:self.delete_backspace() dict abort
  return self._delete(1) " X, [count]X
endfunction

function! s:self._delete(direction) dict abort
  if v:count > 1
    call self.view.start_delete()
    if a:direction
      call self.view.move_left()
    else
      call self.view.move_right()
    endif
  endif
  return self.close_buffers(v:count > 1, a:direction)
endfunction

function! s:self.delete_to_end() dict abort
  if empty(self.view.visual_mode) " D
    call self.view.start_delete()
    if v:count > 1 " [count]D
      call self.view.move_line_head()
      call self.view.move_down(v:count - 1)
    endif
  endif
  if self.view.visual_mode !=# '<C-v>'
    call self.view.move_line_last()
  endif
  let self.view.delete_to_end = 1 " <C-v>G$D
  return self.close_buffers(1)
endfunction

function! s:self.exit() dict abort
  bdelete!
  return 1
endfunction

function! s:self.mouse_select() dict abort
  if self.view.update_select() == 0
    return self.select()
  endif
endfunction

function! s:self.update_filter() dict abort
  let input = self.view.get_input()
  let width = winwidth(0) / 8
  let padding = repeat(' ', (winwidth(0) - max([thumbnail#string#strdisplaywidth(input), width])) / 2)
  let bufnr = -1
  if self.buffers.has(self.view.index)
    let bufnr = self.buffers.get(self.view.index).bufnr
  endif
  call self.buffers.filter(split(input, '\v\s+'))
  let index = self.buffers.index_of(bufnr)
  if index < 0 && self.buffers.len() > 0
    let index = 0
  endif
  call self.view.prepare(self.buffers.len(), index)
  call self.view.set_input(padding . input)
  call self.view.redraw(self.buffers.list())
  return self.view.action('start_insert')
endfunction

function! s:self.redraw() dict abort
  return self.view.redraw(self.buffers.list())
endfunction

function! s:self.gather() dict abort
  return self.buffers.gather()
endfunction

function! s:self.empty() dict abort
  return self.buffers.empty()
endfunction

function! s:self.drag() dict abort
  let index = self.view.nearest_index()
  let self.view.save_cursor = 1
  if index >= 0
    call self.buffers.move(self.view.index, index)
    let self.view.index = index
  else
    return 1
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
