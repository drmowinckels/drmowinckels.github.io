import Alpine from 'alpinejs'

Alpine.store('theme', {
  dark: localStorage.getItem('theme') !== 'light' &&
        !(localStorage.getItem('theme') === null &&
          window.matchMedia('(prefers-color-scheme: light)').matches),
  toggle() {
    this.dark = !this.dark
    localStorage.setItem('theme', this.dark ? 'dark' : 'light')
  }
})

window.Alpine = Alpine
Alpine.start()
