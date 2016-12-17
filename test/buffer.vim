let s:suite = themis#suite('buffer')
let s:assert = themis#helper('assert')

function! s:suite.bufnr()
  tabnew thumbnail-buffer-bufnr-test
  let buffer = thumbnail#buffer#new(bufnr('%'))
  call s:assert.equals(buffer.bufnr, bufnr('%'))
endfunction

function! s:suite.name()
  tabnew thumbnail-buffer-name-test
  let buffer = thumbnail#buffer#new(bufnr('%'))
  call s:assert.equals(buffer.name, 'thumbnail-buffer-name-test')
endfunction

function! s:suite.get_contents()
  tabnew thumbnail-buffer-contents-test
  call setline(1, range(10))
  let buffer = thumbnail#buffer#new(bufnr('%'))
  let contents = insert(map(range(10), 'v:val . repeat(" ", 15)'), 'thu .. ents-test', 0)
  call s:assert.equals(buffer.get_contents(20, 15), contents)
endfunction

function! s:suite.matches_no_name()
  tabnew
  let buffer = thumbnail#buffer#new(bufnr('%'))
  call s:assert.equals(buffer.matches([['']]), 1)
  call s:assert.equals(buffer.matches(['No']), 1)
  call s:assert.equals(buffer.matches(['Name']), 1)
  call s:assert.equals(buffer.matches(['name', 'no']), 1)
  call s:assert.equals(buffer.matches(['example']), 0)
endfunction

function! s:suite.matches_name()
  tabnew thumbnail-buffer-matches-test
  let buffer = thumbnail#buffer#new(bufnr('%'))
  call s:assert.equals(buffer.matches([['']]), 1)
  call s:assert.equals(buffer.matches(['name']), 0)
  call s:assert.equals(buffer.matches(['mat']), 1)
  call s:assert.equals(buffer.matches(['example']), 0)
  call s:assert.equals(buffer.matches(['tes', 'nail']), 1)
  call s:assert.equals(buffer.matches(['mat', 'tes', 'thu']), 1)
  call s:assert.equals(buffer.matches(['mat', 'tes', 'exa']), 0)
endfunction
