return {
  -- TokyoNightテーマを追加
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- storm, moon, night, day から選択
      style = "storm",
    },
  },

  -- LazyVimにTokyoNight Stormを適用
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-storm",
    },
  },
}