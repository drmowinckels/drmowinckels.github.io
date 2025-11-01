function Figure(fig)
  -- Check if there's an image in the figure
  local img = fig.content[1]
  
  if img and img.t == "Plain" and img.content[1] and img.content[1].t == "Image" then
    local image = img.content[1]
    local alt_text = pandoc.utils.stringify(image.caption)
    local src = image.src
    local title = image.title or ""
    
    -- Get caption from figure if it exists
    local caption_text = ""
    if fig.caption and fig.caption.long then
      caption_text = pandoc.utils.stringify(fig.caption.long)
    end
    
    -- Build markdown image syntax
    -- If we have both alt and caption, use alt for alt text and title for caption
    -- Hugo's render hook can access .Title for the caption
    local markdown_img = ""
    
    if caption_text ~= "" and alt_text ~= caption_text then
      -- Both alt and caption exist and differ
      markdown_img = "![" .. alt_text .. "](" .. src .. ' "' .. caption_text .. '")'
    elseif caption_text ~= "" then
      -- Only caption (use as alt)
      markdown_img = "![" .. caption_text .. "](" .. src .. ")"
    elseif title ~= "" then
      -- Original had a title attribute
      markdown_img = "![" .. alt_text .. "](" .. src .. ' "' .. title .. '")'
    else
      -- Just alt text
      markdown_img = "![" .. alt_text .. "](" .. src .. ")"
    end
    
    -- Return as a plain paragraph with the markdown image
    return pandoc.Para({pandoc.RawInline("markdown", markdown_img)})
  end
  
  -- If it's not a simple image figure, return as-is
  return fig
end