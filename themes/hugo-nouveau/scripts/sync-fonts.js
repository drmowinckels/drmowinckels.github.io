const fs = require('fs')
const path = require('path')

const fontMap = {
  'cormorant-garamond': {
    pkg: '@fontsource/cormorant-garamond',
    files: [
      { weight: 400, style: 'normal' },
      { weight: 400, style: 'italic' },
      { weight: 600, style: 'normal' },
      { weight: 700, style: 'normal' },
    ]
  },
  'eb-garamond': {
    pkg: '@fontsource/eb-garamond',
    files: [
      { weight: 400, style: 'normal' },
      { weight: 400, style: 'italic' },
      { weight: 500, style: 'normal' },
      { weight: 500, style: 'italic' },
    ]
  },
  'raleway': {
    pkg: '@fontsource/raleway',
    files: [
      { weight: 400, style: 'normal' },
      { weight: 500, style: 'normal' },
      { weight: 600, style: 'normal' },
    ]
  },
}

const assetsDir = path.join(__dirname, '..', 'assets', 'fonts')

for (const [family, config] of Object.entries(fontMap)) {
  const destDir = path.join(assetsDir, family)
  fs.mkdirSync(destDir, { recursive: true })

  for (const { weight, style } of config.files) {
    const srcDir = path.join(__dirname, '..', 'node_modules', config.pkg, 'files')
    const destName = `${family}-latin-${weight}-${style}.woff2`
    const destPath = path.join(destDir, destName)

    if (fs.existsSync(destPath)) continue

    const srcPattern = `${family}-latin-${weight}-${style}.woff2`
    const srcPath = path.join(srcDir, srcPattern)

    if (fs.existsSync(srcPath)) {
      fs.copyFileSync(srcPath, destPath)
      console.log(`  copied ${destName}`)
    } else {
      const files = fs.existsSync(srcDir) ? fs.readdirSync(srcDir) : []
      const match = files.find(f => f.includes(`${weight}`) && f.includes(style) && f.endsWith('.woff2') && f.includes('latin'))
      if (match) {
        fs.copyFileSync(path.join(srcDir, match), destPath)
        console.log(`  copied ${match} -> ${destName}`)
      } else {
        console.warn(`  WARN: could not find ${destName} in ${srcDir}`)
      }
    }
  }
}

console.log('Font sync complete.')
