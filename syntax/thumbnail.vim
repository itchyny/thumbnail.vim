
syntax match ThumbnailSelect '\[|.*|\]' contains=ThumbnailSMarker 
syntax match ThumbnailSMarker '\[|\||\]' contained
syntax match ThumbnailMarker '\[\\\|\\\]'

highlight ThumbnailSelect term=none cterm=none ctermbg=235 gui=none guibg=#262626
highlight default link ThumbnailSMarker Ignore
highlight default link ThumbnailMarker Ignore

setlocal nocursorcolumn nocursorline

