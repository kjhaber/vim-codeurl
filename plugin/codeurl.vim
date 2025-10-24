function! s:GetGitRepoInfo(start_line, end_line)
    " Get the git repository root directory
    let l:repo_root = system('git rev-parse --show-toplevel 2>/dev/null')
    let l:repo_root = trim(l:repo_root)

    " Check if we're in a git repository
    if v:shell_error != 0 || empty(l:repo_root)
        return {}
    endif

    " Get the relative path of the current file from repo root
    let l:relative_path = system('git ls-files --full-name ' . shellescape(expand('%')))
    let l:relative_path = trim(l:relative_path)

    " Get current branch name
    let l:branch = system('git rev-parse --abbrev-ref HEAD 2>/dev/null')
    let l:branch = trim(l:branch)

    " Get current commit hash
    let l:commit_hash = system('git rev-parse HEAD 2>/dev/null')
    let l:commit_hash = trim(l:commit_hash)

    " Get the remote URL
    let l:remote_url = system('git config --get remote.origin.url 2>/dev/null')
    let l:remote_url = trim(l:remote_url)

    " Convert SSH URL to HTTPS if needed
    if l:remote_url =~# '^git@'
        let l:remote_url = substitute(l:remote_url, '^git@\([^:]\+\):', 'https://\1/', '')
        let l:remote_url = substitute(l:remote_url, '\.git$', '', '')
    endif

    return {
        \   'repo_root': l:repo_root,
        \   'relative_path': l:relative_path,
        \   'start_line': a:start_line,
        \   'end_line': a:end_line,
        \   'branch': l:branch,
        \   'commit_hash': l:commit_hash,
        \   'remote_url': l:remote_url
        \ }
endfunction

function! s:GenerateGitHubURL(repo_info, is_permalink)
    " Validate repo info
    if empty(a:repo_info)
        return ''
    endif

    " Determine which commit/branch to use
    let l:commit = a:is_permalink ? a:repo_info['commit_hash'] : a:repo_info['branch']

    " Construct GitHub URL with line range if applicable
    let l:url = a:repo_info['remote_url'] . '/blob/' . l:commit . '/' . a:repo_info['relative_path'] . '#L' . a:repo_info['start_line']

    " Add range if multiple lines are selected
    if a:repo_info['start_line'] != a:repo_info['end_line']
        let l:url = l:url . '-L' . a:repo_info['end_line']
    endif

    return l:url
endfunction

function! s:DisplayUrlsInBuffer(current_url, permalink_url)
    " Create a new buffer
    let l:bufnr = bufnr('CodeUrl', 1)

    " Get the window number if this buffer is already open somewhere
    let l:winid = bufwinid(l:bufnr)

    " If the buffer is already open in a window, switch to it
    if l:winid != -1
        call win_gotoid(l:winid)
    else
        " Otherwise open a new split with the buffer
        execute 'split +buffer' . l:bufnr
    endif

    " Prepare the buffer
    setlocal modifiable
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted

    " Clear the buffer
    silent! %delete _

    " Add the URLs to the buffer
    call append(0, [
        \ 'Current URL:   ' . a:current_url,
        \ 'Permalink URL: ' . a:permalink_url
    \])

    " Delete empty line at the end
    $delete _

    " Set cursor to the first line
    call cursor(1, 1)

    " Make the buffer non-modifiable
    setlocal nomodifiable

    " Define buffer-local mappings
    nnoremap <buffer> <silent> y :call <SID>YankLine()<CR>
    nnoremap <buffer> <silent> Y :call <SID>YankLine()<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>OpenUrl()<CR>

    " Define autocommands
    augroup CodeUrlBuffer
        autocmd!
        autocmd BufLeave <buffer> if bufname("%") != "CodeUrl" | bwipeout! | endif
    augroup END

    " Message to user
    echo "Press y to copy URL, <CR> to open in browser"
endfunction

function! s:YankLine()
    " Get the URL part from the current line (everything after the colon and spaces)
    let l:line = getline('.')
    let l:url = matchstr(l:line, '\v:\s+\zs.*$')

    " Yank to the clipboard
    let @+ = l:url
    let @" = l:url

    " Show a message
    echo "URL copied to clipboard: " . l:url
endfunction

function! s:OpenUrl()
    " Get the URL part from the current line (everything after the colon and spaces)
    let l:line = getline('.')
    let l:url = matchstr(l:line, '\v:\s+\zs.*$')

    " Open the URL in the default browser
    if has('mac')
        call system('open ' . shellescape(l:url))
    elseif has('unix')
        call system('xdg-open ' . shellescape(l:url) . ' &>/dev/null &')
    elseif has('win32') || has('win64')
        call system('start "" ' . shellescape(l:url))
    endif

    echo "Opening URL in browser: " . l:url
endfunction

function! s:CodeUrl(line1, line2)
    " Get repository information
    let l:repo_info = s:GetGitRepoInfo(a:line1, a:line2)

    " Check if we're in a git repository
    if empty(l:repo_info)
        echo "Current line is not in source control"
        return
    endif

    " Generate URLs
    let l:current_url = s:GenerateGitHubURL(l:repo_info, 0)
    let l:permalink_url = s:GenerateGitHubURL(l:repo_info, 1)

    " Display URLs in a custom buffer
    call s:DisplayUrlsInBuffer(l:current_url, l:permalink_url)
endfunction

" Define the command to explicitly pass range
command! -range CodeUrl call s:CodeUrl(<line1>, <line2>)
