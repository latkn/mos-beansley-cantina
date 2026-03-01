/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx,css}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Source Sans 3', 'system-ui', 'sans-serif'],
        display: ['Bitter', 'Georgia', 'serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      colors: {
        cantina: {
          bg: '#1c1916',
          surface: '#2a2521',
          card: '#352f2a',
          border: '#4a443d',
          'border-light': '#5c554c',
          copper: '#b87333',
          'copper-light': '#c17f3a',
          sand: '#d4c4a8',
          amber: '#e5a84a',
          cream: '#f5f0e6',
          muted: '#a89f8f',
          ink: '#2a2521',
          success: '#6b8f71',
          danger: '#c45c4a',
        },
      },
      boxShadow: {
        cantina: '0 4px 14px rgba(0,0,0,0.25), 0 0 0 1px rgba(74,68,61,0.15)',
        'cantina-lg': '0 8px 24px rgba(0,0,0,0.3), 0 0 0 1px rgba(74,68,61,0.2)',
      },
      borderRadius: {
        'cantina': '0.5rem',
        'cantina-lg': '0.75rem',
      },
    },
  },
  plugins: [],
}
