let s:suite = themis#suite('buffers')
let s:assert = themis#helper('assert')

function! s:suite.before_each()
  silent! %bwipeout!
endfunction

function! s:suite.gather()
  tabnew buffers-test0
  tabnew buffers-test1
  tabnew buffers-test2
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), map(range(3), '"buffers-test" . v:val'))
endfunction

function! s:suite.gather_specified()
  tabnew buffers-test0
  setlocal filetype=vim
  tabnew buffers-test1
  setlocal filetype=help
  tabnew buffers-test2
  setlocal filetype=sh
  tabnew
  let buffers = thumbnail#buffers#new({ 'specify': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test0', 'buffers-test2'])
endfunction

function! s:suite.gather_exclude()
  tabnew buffers-test0
  setlocal filetype=vim
  tabnew buffers-test1
  setlocal filetype=help
  tabnew buffers-test2
  setlocal filetype=sh
  tabnew
  let buffers = thumbnail#buffers#new({ 'exclude': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction

function! s:suite.gather_exclude_nobuflisted()
  tabnew buffers-test0
  setlocal filetype=vim nobuflisted
  tabnew buffers-test1
  setlocal filetype=help nobuflisted
  tabnew buffers-test2
  setlocal filetype=sh
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test2'])
endfunction

function! s:suite.gather_nobuflisted_but_included()
  tabnew buffers-test0
  setlocal filetype=vim nobuflisted
  tabnew buffers-test1
  setlocal filetype=help nobuflisted
  tabnew buffers-test2
  setlocal filetype=sh
  tabnew
  let buffers = thumbnail#buffers#new({ 'include': ['help'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1', 'buffers-test2'])
endfunction

function! s:suite.gather_excluded_included()
  tabnew buffers-test0
  setlocal filetype=vim nobuflisted
  tabnew buffers-test1
  setlocal filetype=help nobuflisted
  tabnew buffers-test2
  setlocal filetype=sh nobuflisted
  tabnew
  let buffers = thumbnail#buffers#new({ 'include': ['vim', 'help'], 'exclude': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction

function! s:suite.has_get_len()
  tabnew buffers-test0
  tabnew buffers-test1
  tabnew buffers-test2
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.has(-1), 0)
  call s:assert.equals(buffers.has(0), 1)
  call s:assert.equals(buffers.has(1), 1)
  call s:assert.equals(buffers.has(2), 1)
  call s:assert.equals(buffers.has(3), 0)
  call s:assert.equals(buffers.get(0).name, 'buffers-test0')
  call s:assert.equals(buffers.get(1).name, 'buffers-test1')
  call s:assert.equals(buffers.get(2).name, 'buffers-test2')
  call s:assert.equals(buffers.len(), 3)
  call s:assert.equals(buffers.empty(), 0)
endfunction

function! s:suite.has_get_len_no_buffers()
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.has(-1), 0)
  call s:assert.equals(buffers.has(0), 0)
  call s:assert.equals(buffers.has(1), 0)
  call s:assert.equals(buffers.len(), 0)
  call s:assert.equals(buffers.empty(), 1)
endfunction

function! s:suite.filter()
  tabnew buffers-test00
  tabnew buffers-test01
  tabnew buffers-test10
  tabnew buffers-test11
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.len(), 4)
  call buffers.filter(['test1'])
  call s:assert.equals(buffers.len(), 2)
  call buffers.filter(['test0', 'test1'])
  call s:assert.equals(buffers.len(), 0)
  call buffers.filter([])
  call s:assert.equals(buffers.len(), 4)
endfunction

function! s:suite.open()
  tabnew buffers-test0
  tabnew buffers-test1
  tabnew buffers-test2
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.open(-1), 0)
  let bufnr = buffers.get(2).bufnr
  call s:assert.equals(buffers.open(bufnr), 1)
  call s:assert.equals(bufname('%'), 'buffers-test2')
endfunction

function! s:suite.open_buffer_tabs()
  edit buffers-test0
  edit buffers-test1
  edit buffers-test2
  edit buffers-test3
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.open_buffer_tabs([buffers.get(1).bufnr, buffers.get(0).bufnr]), 1)
  call s:assert.equals(map(tabpagebuflist(1), 'bufname(v:val)'), ['buffers-test3'])
  call s:assert.equals(map(tabpagebuflist(2), 'bufname(v:val)'), ['buffers-test1'])
  call s:assert.equals(map(tabpagebuflist(3), 'bufname(v:val)'), ['buffers-test0'])
endfunction

function! s:suite.close_buffers()
  tabnew buffers-test0
  tabnew buffers-test1
  tabnew buffers-test2
  tabnew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.len(), 3)
  call buffers.close_buffers([0, 2])
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction
