const themeDir = __dirname + '/../../';

module.exports = {
  theme: {
    content: [`${themeDir}/layouts/**/*.html`, `${themeDir}/content/**/*.md`],
    extend: {}
  },
  variants: {},
  plugins: []
}
