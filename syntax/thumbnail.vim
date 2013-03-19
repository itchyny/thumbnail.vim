
syntax match ThumbnailSelect '\[|.*|\]' contains=ThumbnailMarker 
syntax match ThumbnailMarker '\[|\||\]' contained
syntax match ThumbnailMarker '\[\\\|\\\]'

highlight ThumbnailSelect term=none cterm=none ctermbg=235 gui=none guibg=#262626
highlight default link ThumbnailMarker Ignore

setlocal nocursorcolumn nocursorline

