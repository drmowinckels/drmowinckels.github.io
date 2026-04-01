module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
    autoprefixer: {},
    ...(process.env.HUGO_ENVIRONMENT === 'production' && {
      cssnano: {
        preset: ['default', {
          discardComments: {
            removeAll: true,
          },
        }],
      },
    }),
  },
}
