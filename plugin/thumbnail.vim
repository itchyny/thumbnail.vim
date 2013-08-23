" =============================================================================
" Filename: plugin/thumbnail.vim
" Version: 0.4
" Author: itchyny
" License: MIT License
" Last Change: 2013/08/23 19:52:13.
" =============================================================================

if exists('g:loaded_thumbnail') && g:loaded_thumbnail
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,s:complete
      \ Thumbnail call thumbnail#new(<q-args>)

let s:options = [ '-horizontal', '-vertical', '-here', '-newtab', '-below'
      \ , '-include=', '-exclude=', '-specify=' ]
let s:noconflict = [
      \ [ '-horizontal', '-vertical', '-here', '-newtab' ],
      \ [ '-here', '-below' ],
      \ [ '-newtab', '-below' ],
      \ ]

function! s:complete(arglead, cmdline, cursorpos)
  try
    let options = copy(s:options)
    if a:arglead != ''
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

let g:loaded_thumbnail = 1

let &cpo = s:save_cpo
unlet s:save_cpo
