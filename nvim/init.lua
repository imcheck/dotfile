-- Bootstrap lazy.nvim (없으면 자동으로 설치)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Options
vim.opt.number = true          -- 줄 번호 표시
vim.opt.autoindent = true      -- 새 줄에서 이전 줄 들여쓰기 유지
vim.opt.smartindent = true     -- 코드 블록에 맞게 자동 들여쓰기
vim.opt.autowrite = true       -- 버퍼 전환 시 자동 저장
vim.opt.autoread = true        -- 파일이 외부에서 변경되면 자동으로 다시 읽기
vim.opt.laststatus = 2         -- 상태바 항상 표시
vim.opt.shiftwidth = 2         -- 들여쓰기 너비 (>> << 등)
vim.opt.expandtab = true       -- Tab 키 입력 시 스페이스로 변환
vim.opt.softtabstop = 2        -- 편집 시 Tab 키가 몇 칸으로 동작할지
vim.opt.tabstop = 2            -- 파일 내 탭 문자를 몇 칸으로 표시할지
vim.opt.hlsearch = true        -- 검색 결과 하이라이트
vim.opt.incsearch = true       -- 검색어 입력 중 실시간으로 결과 표시
vim.opt.autochdir = true       -- 현재 파일 위치로 작업 디렉토리 자동 변경
vim.opt.clipboard = "unnamed"  -- 시스템 클립보드와 공유
vim.opt.regexpengine = 0       -- 정규식 엔진 자동 선택 (구문 하이라이팅 성능 개선)
vim.opt.completeopt = { "longest", "menuone" } -- 자동완성: 가장 긴 공통 문자열 삽입, 후보 1개여도 메뉴 표시

vim.cmd.colorscheme("habamax")

-- Keymaps
vim.keymap.set("n", "<C-a>", "^", { silent = true })                       -- Ctrl+A: 줄의 첫 번째 문자로 이동
vim.keymap.set("n", "<C-\\>", ":vertical split<CR>", { silent = true })    -- Ctrl+\: 수직 분할
vim.keymap.set("n", "<C-->", ":split<CR>", { silent = true })              -- Ctrl+-: 수평 분할

vim.keymap.set("n", "<A-S-Left>", "20<C-W>>", {})   -- Alt+Shift+←: 창 너비 늘리기
vim.keymap.set("n", "<A-S-Right>", "20<C-W><", {})  -- Alt+Shift+→: 창 너비 줄이기
vim.keymap.set("n", "<A-S-Up>", "20<C-W>+", {})     -- Alt+Shift+↑: 창 높이 늘리기
vim.keymap.set("n", "<A-S-Down>", "20<C-W>-", {})   -- Alt+Shift+↓: 창 높이 줄이기

vim.keymap.set("v", "<Tab>", ">gv", {})              -- 비주얼 모드 Tab: 들여쓰기 후 선택 유지
vim.keymap.set("v", "<S-Tab>", "<gv", {})            -- 비주얼 모드 Shift+Tab: 내어쓰기 후 선택 유지

-- Remember last cursor position
-- 파일을 열 때 마지막으로 편집한 위치로 커서 이동
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Plugins
require("lazy").setup({

  -- lualine: 하단 상태바 (vim-airline 대체)
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup()
    end,
  },

  -- oil.nvim: 파일을 버퍼처럼 탐색/편집 (NERDTree 대체)
  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        view_options = { show_hidden = true }, -- 숨김 파일 표시
      })
      vim.keymap.set("n", "-", require("oil").open, { silent = true, desc = "파일 탐색기 열기" })
    end,
  },

  -- telescope: 파일/텍스트 퍼지 검색
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "파일 검색" })
      vim.keymap.set("n", "<C-g>", builtin.live_grep, { desc = "텍스트 검색" })
    end,
  },

  -- indent-blankline: 들여쓰기 레벨 시각적으로 표시
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({ indent = { char = "▏" } })
    end,
  },

  -- nvim-treesitter: 코드 구조 파싱 (context-aware 주석 등에 필요)
  -- 파서는 ~/.local/share/nvim/site/parser/ 에 수동 컴파일 설치됨
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- 파서가 있는 파일타입에서 treesitter 자동 시작
      vim.api.nvim_create_autocmd("FileType", {
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  -- nvim-ts-context-commentstring: TSX/JSX에서 커서 위치에 맞는 주석 문자 자동 감지
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      require("ts_context_commentstring").setup({ enable_autocmd = false })
    end,
  },

  -- Comment.nvim: 주석 토글 (Ctrl+/)
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
      vim.keymap.set("n", "<C-_>", "<Plug>(comment_toggle_linewise_current)", { desc = "주석 토글" })
      vim.keymap.set("v", "<C-_>", "<Plug>(comment_toggle_blockwise_visual)", { desc = "주석 토글 (블록)" })
    end,
  },

  -- neo-tree: 사이드바 트리형 파일 탐색기
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          filtered_items = {
            visible = true, -- 숨김 파일 표시
          },
        },
      })
      vim.keymap.set("n", "<C-b>", ":Neotree toggle<CR>", { silent = true, desc = "파일 트리 토글" })
    end,
  },

  -- render-markdown: 마크다운 파일을 헤딩/코드블록/테이블 등 예쁘게 렌더링
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    config = function()
      require("render-markdown").setup({})
    end,
  },

  -- vim-better-whitespace: 불필요한 공백 표시
  "ntpeters/vim-better-whitespace",

  -- vim-helm: Helm chart 문법 하이라이팅 (helm 바이너리가 있을 때만 로드)
  {
    "towolf/vim-helm",
    cond = vim.fn.executable("helm") == 1,
  },

  -- vim-terraform: Terraform 문법 및 저장 시 자동 포맷 (terraform 바이너리가 있을 때만 로드)
  {
    "hashivim/vim-terraform",
    cond = vim.fn.executable("terraform") == 1,
    init = function()
      vim.g.terraform_fmt_on_save = 1 -- 저장 시 terraform fmt 자동 실행
    end,
  },

})

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)         -- 정의로 이동
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)         -- 참조 목록
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)               -- 문서 보기
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)     -- 이름 변경
  end,
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", ".git" },
})
vim.lsp.enable("gopls")
