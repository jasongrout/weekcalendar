-- gridlib.lua: Shared grid drawing library for LaTeX documents

local gridlib = {}

function gridlib.pt2in(pt)
  return pt / 72.0
end

-- Convert TeX scaled points to inches
-- TeX dimensions are stored in scaled points (sp), where 1pt = 65536sp
function gridlib.sp2in(sp)
  return sp / 65536 / 72.27
end

-- Read page dimensions from TeX (set by geometry package)
-- Returns paper_width, paper_height, text_width, text_height in inches
function gridlib.get_page_dimensions()
  local paper_width = gridlib.sp2in(tex.dimen.paperwidth)
  local paper_height = gridlib.sp2in(tex.dimen.paperheight)
  local text_width = gridlib.sp2in(tex.dimen.textwidth)
  local text_height = gridlib.sp2in(tex.dimen.textheight)
  return paper_width, paper_height, text_width, text_height
end

-- Draw a grid using TikZ with labels along the top and left side
-- Parameters:
--   width: total width of grid area in inches
--   height: total height of grid area in inches
--   top_labels: array of strings for column headers
--   left_labels: array of strings for row headers
--   options: table with optional settings:
--     top_font_size: TeX font size command (default: \Huge)
--     left_font_size: TeX font size command (default: \Huge)
--     left_margin: width in inches for left label column (default: 1.0)
--     header_height: height in inches for top label row (default: 0.5)
--     gap: gap between boxes in inches (default: 0.04)
--     line_width: box border thickness in points (default: 0.2, matches \fboxrule)
--     cell_content: function(row, col) returning TeX string for cell content (default: nil)
function gridlib.draw_grid(width, height, top_labels, left_labels, options)
  options = options or {}
  local top_font = options.top_font_size or [[\Huge]]
  local left_font = options.left_font_size or [[\Huge]]
  local left_margin = options.left_margin or 1.0
  local header_height = options.header_height or 0.5
  local gap = options.gap or 0.04
  local line_width = options.line_width or 0.4
  local cell_content = options.cell_content

  local num_cols = #top_labels
  local num_rows = #left_labels

  -- Calculate cell dimensions
  local box_area_width = width - left_margin
  local box_area_height = height - header_height

  local cell_width = (box_area_width - (num_cols - 1) * gap) / num_cols
  local cell_height = (box_area_height - (num_rows - 1) * gap) / num_rows

  texio.write_nl(string.format('TikZ grid - Total: %.3fin x %.3fin, Cell: %.3fin x %.3fin', width, height, cell_width, cell_height))

  -- Start TikZ picture
  tex.print([=[\noindent\begin{tikzpicture}[x=1in, y=1in]]=])

  -- Draw column labels (top)
  for col = 1, num_cols do
    local x = left_margin + (col - 1) * (cell_width + gap) + cell_width / 2
    local y = height - header_height / 2
    tex.print(string.format([=[\node[font=%s] at (%.4f, %.4f) {%s};]=],
      top_font, x, y, top_labels[col]))
  end

  -- Draw row labels (left)
  for row = 1, num_rows do
    local x = left_margin / 2
    local y = box_area_height - (row - 1) * (cell_height + gap) - cell_height / 2
    tex.print(string.format([=[\node[font=%s] at (%.4f, %.4f) {%s};]=],
      left_font, x, y, left_labels[row]))
  end

  -- Draw grid of boxes
  for row = 1, num_rows do
    for col = 1, num_cols do
      local x = left_margin + (col - 1) * (cell_width + gap)
      local y = box_area_height - (row - 1) * (cell_height + gap) - cell_height
      tex.print(string.format([=[\draw[line width=%.1fpt] (%.4f, %.4f) rectangle (%.4f, %.4f);]=],
        line_width, x, y, x + cell_width, y + cell_height))

      -- Draw cell content if provided (bottom-left aligned)
      if cell_content then
        local content = cell_content(row, col)
        if content and content ~= "" then
          tex.print(string.format([=[\node[anchor=south west, inner sep=2pt] at (%.4f, %.4f) {%s};]=],
            x, y, content))
        end
      end
    end
  end

  tex.print([=[\end{tikzpicture}]=])

  return {
    cell_width = cell_width,
    cell_height = cell_height
  }
end

-- Helper to generate a range of numbers as string labels
function gridlib.number_range(start, count)
  local labels = {}
  for i = 0, count - 1 do
    labels[#labels + 1] = tostring(start + i)
  end
  return labels
end

-- Month names
gridlib.month_names = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
}

-- Month name abbreviations
gridlib.month_names_short = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}


-- Print pdfcrop command for extracting a test section from the PDF
-- Parameters:
--   pdf_name: output PDF filename (e.g., "calendar.pdf")
--   paper_width, paper_height: full page dimensions in inches
--   test_width, test_height: size of test section to extract (default: 8.5x11)
function gridlib.print_crop_command(pdf_name, paper_width, paper_height, test_width, test_height)
  test_width = test_width or 8.5
  test_height = test_height or 11
  local crop_width = test_width * 72  -- convert to points
  local crop_height = test_height * 72  -- convert to points
  local total_height = paper_height * 72  -- total page height in points
  local crop_bottom = total_height - crop_height
  local output_name = pdf_name:gsub("%.pdf$", "") .. "-test.pdf"
  texio.write_nl(string.format('**********************************'))
  texio.write_nl(string.format('To print upper-left %.1fx%.1f test section, run:', test_width, test_height))
  texio.write_nl(string.format('pdfcrop --bbox "0 %.0f %.0f %.0f" %s %s',
    crop_bottom, crop_width, total_height, pdf_name, output_name))
  texio.write_nl(string.format('**********************************'))
end

return gridlib
