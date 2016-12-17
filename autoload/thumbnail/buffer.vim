" =============================================================================
" Filename: autoload/thumbnail/buffer.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/17 19:26:01.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! thumbnail#buffer#new(bufnr) abort
  let self = deepcopy(s:self)
  let self.bufnr = a:bufnr
  call self.set_bufname()
  call self.set_lines()
  return self
endfunction

let s:self = {}

let s:self.bufnr = -1

let s:self.name = ''

let s:self.lines = []

let s:self.contents_cache = {}

function! s:self.set_bufname() dict abort
  let bufname = bufname(self.bufnr)
  if bufloaded(self.bufnr) && bufexists(self.bufnr)
    let lines = getbufline(self.bufnr, 1, &lines)
  elseif bufname !=# '' && filereadable(bufname)
    let lines = readfile(bufname, '', &lines)
  else
    let lines = []
  endif
  let name = bufname
  let abbrnames = []
  call add(abbrnames, substitute(bufname, expand('~'), '~', ''))
  let updir = substitute(expand('%:p:h'), '[^/]*$', '', '')
  call add(abbrnames, substitute(bufname, escape(updir, '.$*'), '../', ''))
  let upupdir = substitute(updir, '[^/]*/$', '', '')
  call add(abbrnames, substitute(bufname, escape(upupdir, '.$*'), '../../', ''))
  for abbrname in abbrnames
    let name = len(name) > len(abbrname) ? abbrname : name
  endfor
  let self.name = name
endfunction

function! s:self.set_lines() dict abort
  let bufname = bufname(self.bufnr)
  if bufloaded(self.bufnr) && bufexists(self.bufnr)
    let lines = getbufline(self.bufnr, 1, &lines)
  elseif bufname !=# '' && filereadable(bufname)
    let lines = readfile(bufname, '', &lines)
  else
    let lines = []
  endif
  let tabspaces = repeat(' ', getbufvar(self.bufnr, '&tabstop'))
  let self.lines = map(lines, 'substitute(v:val, "\t", tabspaces, "g")')
endfunction

function! s:self.get_contents(width, height) dict abort
  let key = a:width . ',' . a:height
  if has_key(self.contents_cache, key)
    return self.contents_cache[key]
  endif
  let lines = self.lines[:(a:height - 2)]
  if match(lines, '[\x00-\x08]') >= 0
    let lines = repeat([''], a:height / 2 - 2)
    call extend(lines, [repeat(' ', (a:width - 4) / 2 - 7) . '[Binary file]'])
  endif
  call insert(lines, thumbnail#string#truncate_smart(self.name ==# '' ? '[No Name]' : self.name,
        \ a:width - 4, (a:width - 4) * 3 / 5, ' .. '))
  let self.contents_cache[key] = map(lines, 'thumbnail#string#truncate(v:val,' . (a:width - 4) . ')')
  return self.contents_cache[key]
endfunction

function! s:self.matches(words) dict abort
  let result = 1
  let name = self.name ==# '' ? '[No Name]' : self.name
  for word in a:words
    try
      if name !~? word
        let result = 0
      endif
    catch
      try
        if name !~? escape(word, '~\*[]?')
          let result = 0
        endif
      catch
      endtry
    endtry
    if !result
      break
    endif
  endfor
  return result
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
