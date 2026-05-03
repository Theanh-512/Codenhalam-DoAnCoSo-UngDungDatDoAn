/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#fff7ed',
          100: '#ffedd5',
          200: '#fed7aa',
          300: '#fdba74',
          400: '#fb923c',
          500: '#E67E22', // Main Orange
          600: '#d97706',
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
        },
        accent: {
          light: '#F1F8E9', // Light Green Background
          medium: '#81C784', // Green Accent
          dark: '#2E7D32',   // Dark Green
        }
      }
    },
  },
  plugins: [],
}
