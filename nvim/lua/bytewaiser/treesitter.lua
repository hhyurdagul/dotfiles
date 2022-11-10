require 'nvim-treesitter.configs'.setup {
    ensure_installed = {
        "astro", "bash", "c", "cmake", "commonlisp", "cpp", "css", "dockerfile",
        "elixir", "elm", "fish", "fortran", "git_rebase", "gitattributes", "gitignore", "go",
        "gomod", "gowork", "html", "http", "javascript", "jsdoc", "json", "json5", "jsonc",
        "jsonnet", "julia", "latex", "llvm", "lua", "make", "markdown", "markdown_inline",
        "python", "qmljs", "query", "r", "racket", "rasi", "regex", "rst", "ruby", "rust",
        "scss", "solidity", "sql", "svelte", "swift", "sxhkdrc", "todotxt", "toml", "tsx",
        "typescript", "vim", "vue", "yaml", "zig"
    }, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    ignore_install = {"phpdoc"}, -- List of parsers to ignore installing
    highlight = {
        enable = true, -- false will disable the whole extension
        disable = {}, -- list of language that will be disabled
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
