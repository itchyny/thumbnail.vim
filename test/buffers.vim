let s:suite = themis#suite('buffers')
let s:assert = themis#helper('assert')

function! s:suite.before_each()
  %bwipeout!
endfunction

function! s:suite.gather()
  edit buffers-test0
  edit buffers-test1
  edit buffers-test2
  enew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), map(range(3), '"buffers-test" . v:val'))
endfunction

function! s:suite.gather_specified()
  edit buffers-test0
  setlocal filetype=vim
  edit buffers-test1
  setlocal filetype=help
  edit buffers-test2
  setlocal filetype=sh
  enew
  let buffers = thumbnail#buffers#new({ 'specify': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test0', 'buffers-test2'])
endfunction

function! s:suite.gather_exclude()
  edit buffers-test0
  setlocal filetype=vim
  edit buffers-test1
  setlocal filetype=help
  edit buffers-test2
  setlocal filetype=sh
  enew
  let buffers = thumbnail#buffers#new({ 'exclude': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction

function! s:suite.gather_exclude_nobuflisted()
  edit buffers-test0
  setlocal filetype=vim nobuflisted
  edit buffers-test1
  setlocal filetype=help nobuflisted
  edit buffers-test2
  setlocal filetype=sh
  enew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test2'])
endfunction

function! s:suite.gather_nobuflisted_but_included()
  edit buffers-test0
  setlocal filetype=vim nobuflisted
  edit buffers-test1
  setlocal filetype=help nobuflisted
  edit buffers-test2
  setlocal filetype=sh
  enew
  let buffers = thumbnail#buffers#new({ 'include': ['help'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1', 'buffers-test2'])
endfunction

function! s:suite.gather_excluded_included()
  edit buffers-test0
  setlocal filetype=vim nobuflisted
  edit buffers-test1
  setlocal filetype=help nobuflisted
  edit buffers-test2
  setlocal filetype=sh nobuflisted
  enew
  let buffers = thumbnail#buffers#new({ 'include': ['vim', 'help'], 'exclude': ['vim', 'sh'] })
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction

function! s:suite.has_get_len()
  edit buffers-test0
  edit buffers-test1
  edit buffers-test2
  enew
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
endfunction

function! s:suite.has_get_len_no_buffers()
  enew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.has(-1), 0)
  call s:assert.equals(buffers.has(0), 0)
  call s:assert.equals(buffers.has(1), 0)
  call s:assert.equals(buffers.len(), 0)
endfunction

function! s:suite.filter()
  edit buffers-test00
  edit buffers-test01
  edit buffers-test10
  edit buffers-test11
  enew
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
  edit buffers-test0
  edit buffers-test1
  edit buffers-test2
  enew
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
  enew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.open_buffer_tabs([buffers.get(1).bufnr, buffers.get(0).bufnr]), 1)
  call s:assert.equals(map(tabpagebuflist(1), 'bufname(v:val)'), ['buffers-test1'])
  call s:assert.equals(map(tabpagebuflist(2), 'bufname(v:val)'), ['buffers-test0'])
endfunction

function! s:suite.close_buffers()
  edit buffers-test0
  edit buffers-test1
  edit buffers-test2
  enew
  let buffers = thumbnail#buffers#new({})
  call buffers.gather()
  call s:assert.equals(buffers.len(), 3)
  call buffers.close_buffers([0, 2])
  call buffers.gather()
  call s:assert.equals(map(copy(buffers.list()), 'v:val.name'), ['buffers-test1'])
endfunction
