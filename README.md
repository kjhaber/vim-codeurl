# vim-codeurl

This Vim plugin provides a simple command to access the remote Git repository
URL of the current buffer.  By running `:CodeUrl`, a separate buffer will open
that shows the URL for current branch and a permalink url for the current
commit.

Move the cursor to the desired url and press Enter to open the url in browser
(similar to `gx`), or press 'y' to yank the url to the clipboard.

The urls in CodeUrl window will include parameters to select either the current
cursor line or visually selected range.


## Installation
Installation is as usual for modern Vim plugin managers:

lazy.nvim:
```
  {
    "kjhaber/vim-codeurl",
    init = function()
      vim.keymap.set("n", "<leader>cu", ":CodeUrl<CR>", { noremap = true })
      vim.keymap.set("v", "<leader>cu", ":'<,'>CodeUrl<CR>", { noremap = true })
    end
  } 
```

vim-plug:
```
  Plug 'kjhaber/vim-codeurl'
```


## Notes
This plugin was almost entirely written using Claude 3.7 Sonnet.  It took a few
prompt iterations, and I'm getting the hang of LLM-centric software development,
but so far I like the result.

Fair warning: this is a quickly thrown-together tool, and testing for this
plugin is very sparse. I've only used it with Neovim/lazy.nvim and Github, though nothing
in the code should be specific to nvim or Github.  Caveat emptor, works on my
machine, etc etc.


## License
MIT

