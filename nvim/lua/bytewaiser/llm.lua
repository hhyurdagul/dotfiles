local llm = require('llm')

llm.setup({

  backend = "ollama",
  url = "http://127.0.0.1:11434", -- the http url of the backend
  tokens_to_clear = { "<EOT>" },
  fim = {
    enabled = true,
    prefix = "<PRE> ",
    middle = " <MID>",
    suffix = " <SUF>",
  },
  model = "codellama",
  context_window = 4096,
})
