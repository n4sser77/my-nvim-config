---@type ChadrcConfig
local M = {}

M.base46 = {
    theme = "decay",
    transparency = true,
    hl_override = {
        Comment = { italic = true },
        ["@comment"] = { italic = true },
        Visual = { bg = "#2d4263" },

        -- =========================
        -- Render Markdown
        -- =========================
        RenderMarkdownCode = { bg = "dark_purple" },
        RenderMarkdownCodeInfo = { fg = "dark_purple" },
        RenderMarkdownCodeBorder = { fg = "dark_purple" },
        RenderMarkdownCodeFallback = { fg = "dark_purple" },
        RenderMarkdownCodeInline = { bg = "dark_purple" },
        RenderMarkdownBullet = { fg = "green" },
        RenderMarkdownInfo = { fg = "blue" },
        RenderMarkdownSuccess = { fg = "green" },
        RenderMarkdownWarn = { fg = "yellow" },
        RenderMarkdownError = { fg = "red" },
        RenderMarkdownQuote = { fg = "cyan" },
        RenderMarkdownUnchecked = { fg = "grey" },
        RenderMarkdownChecked = { fg = "green" },
        RenderMarkdownTodo = { fg = "yellow" },
        RenderMarkdownDash = { fg = "yellow" },
        RenderMarkdownHtmlComment = { fg = "grey" },
        RenderMarkdownIndent = { fg = "grey" },
        RenderMarkdownInlineHighlight = { bg = "dark_purple" },
        RenderMarkdownMath = { fg = "purple" },
        RenderMarkdownLink = { fg = "cyan", underline = true },
        RenderMarkdownLinkTitle = { fg = "yellow" },
        RenderMarkdownSign = { fg = "green" },
    },
}

M.nvdash = { load_on_startup = true }

M.ui = {
    tabufline = {
        lazyload = false,
    },
}

return M
