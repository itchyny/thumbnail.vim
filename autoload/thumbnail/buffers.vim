" =============================================================================
" Filename: autoload/thumbnail/buffers.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/18 09:41:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#buffers#new(ftconfig) abort
  let self = deepcopy(s:self)
  let self.ftconfig = a:ftconfig
  return self
endfunction

let s:self = {}

let s:self.buffers = []

function! s:self.gather() dict abort
  setlocal nobuflisted
  let bufnrs = []
  let has_specified = !empty(get(self.ftconfig, 'specify', []))
  for nr in range(1, bufnr('$'))
    let empty = (bufname(nr) ==# '' && (!bufexists(nr) || !bufloaded(nr) || !getbufvar(nr, '&modified'))) || !buflisted(nr)
    let bufft = getbufvar(nr, '&filetype')
    let specified = index(get(self.ftconfig, 'specify', []), bufft) >= 0
    let excluded = index(get(self.ftconfig, 'exclude', []), bufft) >= 0
    let included = index(get(self.ftconfig, 'include', []), bufft) >= 0
    if (!has_specified && !excluded && (!empty || included)) || (has_specified && !excluded && (specified || included))
      call add(bufnrs, nr)
    endif
  endfor
  let self.all_buffers = map(bufnrs, 'thumbnail#buffer#new(v:val)')
  let self.buffers = copy(self.all_buffers)
endfunction

function! s:self.list() dict abort
  return self.buffers
endfunction

function! s:self.has(index) dict abort
  return 0 <= a:index && a:index < len(self.buffers)
endfunction

function! s:self.get(index) dict abort
  return self.buffers[a:index]
endfunction

function! s:self.len() dict abort
  return len(self.buffers)
endfunction

function! s:self.empty() dict abort
  return empty(self.buffers)
endfunction

function! s:self.filter(words) dict abort
  let self.buffers = filter(copy(self.all_buffers), 'v:val.matches(a:words)')
endfunction

function! s:self.index_of(bufnr) dict abort
  return index(map(copy(self.buffers), 'v:val.bufnr'), a:bufnr)
endfunction

function! s:self.move(index, target) dict abort
  let selection = self.buffers[a:index]
  call remove(self.buffers, a:index)
  call insert(self.buffers, selection, a:target)
endfunction

function! s:self.open(bufnr) dict abort
  let current_bufnr = bufnr('%')
  if bufloaded(a:bufnr)
    if bufwinnr(a:bufnr) != -1
      execute bufwinnr(a:bufnr) 'wincmd w'
      execute current_bufnr 'bdelete!'
      return 1
    endif
    for i in range(1, tabpagenr('$'))
      if index(tabpagebuflist(i), a:bufnr) != -1
        execute 'tabnext' i
        execute bufwinnr(a:bufnr) 'wincmd w'
        execute current_bufnr 'bdelete!'
        return 1
      endif
    endfor
    execute a:bufnr 'buffer!'
    return 1
  elseif buflisted(a:bufnr)
    execute a:bufnr 'buffer!'
    return 1
  else
    echohl ErrorMsg
    echomsg 'No buffer found: ' . a:bufnr
    echohl None
  endif
endfunction

function! s:self.open_buffer_tabs(bufnrs) dict abort
  let current_bufnr = bufnr('%')
  let bufnrs = []
  for i in range(1, tabpagenr('$'))
    call extend(bufnrs, tabpagebuflist(i))
  endfor
  for bufnr in a:bufnrs
    if buflisted(bufnr)
      if index(bufnrs, bufnr) == -1
        tabnew
        execute bufnr 'buffer!'
      endif
    endif
  endfor
  execute current_bufnr 'bdelete!'
  return 1
endfunction

function! s:self.close_buffers(indices) dict abort
  let [type, yes_for_all, no_for_all] = [0, 1, 2]
  let bufnrs = map(copy(a:indices), 'self.get(v:val).bufnr')
  let multiple = len(filter(copy(bufnrs), 'getbufvar(v:val, "&modified")')) > 1
  for bufnr in bufnrs
    if getbufvar(bufnr, '&modified')
      if type == yes_for_all
        execute bufnr 'bdelete!'
      elseif type != no_for_all
        let message = printf('The buffer ' . (bufname(bufnr) ==# '' ? '[No Name]' : bufname(bufnr))
              \ . ' is modified. Force to delete the buffer? [yes/no/edit%s] ',
              \ (multiple ? '/Yes for all/No for all' : ''))
        let yesno = input(message)
        if yesno ==# ''
          echo 'Canceled'
          return
        endif
        if yesno =~# '^y\%[es]'
          execute bufnr 'bdelete!'
        elseif yesno =~# '^e\%[dit]'
          return self.open(bufnr)
        elseif yesno =~# '^Y\%[es for all]'
          execute bufnr 'bdelete!'
          let type = yes_for_all
        elseif yesno =~# '^N\%[o for all]'
          let type = no_for_all
        endif
      endif
    elseif bufexists(bufnr)
      execute bufnr 'bdelete!'
    endif
  endfor
  redraw
  echo ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
