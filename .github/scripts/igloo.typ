#set page(
  width: 10cm,          // Square aspect ratio, adjust as needed (e.g., 10cm x 10cm, or 1000pt x 1000pt)
  height: 10cm,
  margin: (x: 0.8cm, y: 0.8cm), // Consistent margins around the content
  fill: white,          // White background for the slides
)

// --- Font Definitions ---
// Using common sans-serif fonts. You can replace these with specific fonts
// if you have them embedded or available, e.g., 'Inter', 'Roboto', 'Open Sans'.
#let body_font = "IBM Plex Sans" // A good sans-serif for body text
#let heading_font = "IBM Plex Sans" // Often good to keep headings and body similar for consistency
#let code_font = "IBM Plex Mono"   // Monospace font for code blocks

#set text(
  font: body_font,
  fill: rgb("#333333"), // Dark gray for body text, not pure black
  size: 11pt,
  linebreaks: "strict", // Control line breaks
)

// --- Colors ---
#let accent_color = rgb("#007bff") // A common blue for accents (e.g., links, subtle highlights)
#let code_bg_color = rgb("#f5f5f5") // Light gray background for code blocks
#let code_border_color = rgb("#e0e0e0") // Subtle border for code blocks

// --- Heading Styles (Slide Titles) ---
// For the main slide title (corresponds to # in Quarto Markdown)
#set heading(
  level: 1,
  font: heading_font,
  size: 20pt,
  weight: "bold",
  spacing: 0.6em, // Space after the title
  fill: rgb("#222222"), // Slightly darker for titles
)

// For sub-headings within a slide (corresponds to ## in Quarto Markdown, used for "Code Input", "Code Output")
#set heading(
  level: 2,
  font: heading_font,
  size: 14pt,
  weight: "medium",
  spacing: 0.4em,
  fill: rgb("#444444"),
)

// --- Code Block Styling ---
#set raw(
  block: true, // Apply to block code
  fill: code_bg_color,
  font: code_font,
  size: 9pt,
  inset: 8pt, // Padding inside the code block
  outset: 0pt, // No extra space outside
  stroke: (x: 0.5pt, y: 0.5pt, paint: code_border_color), // Subtle border
  radius: 4pt, // Slightly rounded corners for the code block
  // Set text color for code blocks
  text: (fill: rgb("#000000")), // Black text for code
)

// --- Link Styling (if you have any in your markdown) ---
#set link(
  underline: false,
  fill: accent_color,
)

// --- Slide Content Container (Optional, but good for consistent layout) ---
// This defines a common container for all content on a slide.
// You can use this if you want to apply a background or border to the
// content area itself, separate from the page background.
#let slide_content(body) = {
  // Example: a simple rectangle for content, if needed
  // rect(
  //   width: 100%,
  //   height: 100%,
  //   inset: 0pt, // No extra padding here, as page margins handle it
  //   fill: white,
  //   body
  // )
  body // For now, just pass the body directly, relying on page margins.
}

// --- Main Template Body ---
// This is where the content from your Quarto Markdown will be placed.
// Typst automatically handles pages based on #heading levels or --- delimiters.
#show: doc => {
  doc.body
}
