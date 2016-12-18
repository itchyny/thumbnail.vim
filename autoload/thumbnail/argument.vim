" =============================================================================
" Filename: autoload/thumbnail/argument.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/12/17 18:46:44.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:options = [ '-horizontal', '-vertical', '-here', '-newtab', '-below'
      \ , '-include=', '-exclude=', '-specify=' ]
let s:noconflict = [
      \ [ '-horizontal', '-vertical', '-here', '-newtab' ],
      \ [ '-here', '-below' ],
      \ [ '-newtab', '-below' ],
      \ ]
function! thumbnail#argument#complete(arglead, cmdline, cursorpos) abort
  try
    let options = copy(s:options)
    if a:arglead !=# ''
      let options = sort(filter(copy(s:options), 'stridx(v:val, a:arglead) != -1'))
      if len(options) == 0
        let arglead = substitute(a:arglead, '^-\+', '', '')
        let options = sort(filter(copy(s:options), 'stridx(v:val, arglead) != -1'))
        if len(options) == 0
          try
            let arglead = substitute(a:arglead, '\(.\)', '.*\1', 'g') . '.*'
            let options = sort(filter(copy(s:options), 'v:val =~? arglead'))
          catch
            let options = copy(s:options)
          endtry
        endif
      endif
    endif
    let d = {}
    for opt in options
      let d[opt] = 0
    endfor
    for opt in options
      if d[opt] == 0
        for ncf in s:noconflict
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
    return sort(filter(options, 'd[v:val] == 0 && stridx(a:cmdline, v:val) == -1'))
  catch
    return s:options
  endtry
endfunction

function! thumbnail#argument#parse(args) abort
  let args = split(a:args, '\s\+')
  let isnewbuffer = bufname('%') != '' || &l:filetype != '' || &modified
  let name = " `='" . thumbnail#argument#buffername('thumbnail') . "'`"
  let command = 'tabnew'
  let below = ''
  let addname = 1
  let ftconfig = { 'include': [], 'exclude': [], 'specify': [] }
  for arg in args
    if arg =~? '^-*horizontal$'
      let command = 'new'
      let isnewbuffer = 1
    elseif arg =~? '^-*vertical$'
      let command = 'vnew'
      let isnewbuffer = 1
    elseif arg =~? '^-*here$'
      let command = 'try | edit' . name . ' | catch | tabnew' . name . ' | endtry'
      let addname = 0
    elseif arg =~? '^-*here!$'
      let command = 'edit!'
    elseif arg =~? '^-*newtab$'
      let command = 'tabnew'
      let isnewbuffer = 1
    elseif arg =~? '^-*below$'
      if command ==# 'tabnew'
        let command = 'new'
      endif
      let below = 'below '
    elseif arg =~? '^-*include=.\+$'
      let ftconfig.include = extend(ftconfig.include, split(substitute(arg, '-*include=', '', ''), ','))
      let ftconfig.exclude = filter(ftconfig.exclude, 'index(ftconfig.include, v:val) < 0')
    elseif arg =~? '^-*exclude=.\+$'
      let ftconfig.exclude = extend(ftconfig.exclude, split(substitute(arg, '-*exclude=', '', ''), ','))
      let ftconfig.include = filter(ftconfig.include, 'index(ftconfig.exclude, v:val) < 0')
    elseif arg =~? '^-*specify=.\+$'
      let ftconfig.specify = extend(ftconfig.specify, split(substitute(arg, '-*specify=', '', ''), ','))
      let ftconfig.include = []
      let ftconfig.exclude = []
    endif
  endfor
  let cmd1 = below . command . (addname ? name : '')
  let cmd2 = 'edit' . name
  let command = 'if isnewbuffer | ' . cmd1 . ' | else | ' . cmd2 . '| endif'
  return [isnewbuffer, command, ftconfig]
endfunction

function! thumbnail#argument#buffername(name) abort
  let buflist = []
  for i in range(1, tabpagenr('$'))
    call extend(buflist, tabpagebuflist(i))
  endfor
  let matcher = 'bufname(v:val) =~# ("\\[" . a:name . "\\( \\d\\+\\)\\?\\]") && index(buflist, v:val) >= 0'
  let substituter = 'substitute(bufname(v:val), ".*\\(\\d\\+\\).*", "\\1", "") + 0'
  let bufs = map(filter(range(1, bufnr('$')), matcher), substituter)
  let index = 0
  while index(bufs, index) >= 0
    let index += 1
  endwhile
  return '[' . a:name . (len(bufs) && index ? ' ' . index : '') . ']'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
