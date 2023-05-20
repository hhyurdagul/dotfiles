require 'nvim-treesitter.configs'.setup {
    ensure_installed = {
        "bash", "c", "cmake", "cpp", "css", "dockerfile", "gitignore", "go",
        "html", "javascript", "json", "json5", "julia", "latex", "llvm", "lua",
        "make", "markdown", "markdown_inline", "python", "r", "rust",
        "svelte", "toml", "tsx", "typescript", "vim"
    },                             -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    ignore_install = { "phpdoc" }, -- List of parsers to ignore installing
    highlight = {
        enable = true,             -- false will disable the whole extension
        disable = {},              -- list of language that will be disabled
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
        indent = {
            enable = true
        },
    },
    autotag = {
        enable = true,
    },
}

vim.g.markdown_fenced_languages = {
    "ts=typescript"
}
