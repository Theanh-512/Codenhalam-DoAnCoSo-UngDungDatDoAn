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
          500: '#f97316',
          600: '#ea580c', // Brand Orange
          700: '#c2410c',
          800: '#9a3412',
          900: '#7c2d12',
        },
        accent: {
          dark: '#111827', // Dark charcoal/gray-900
          medium: '#374151', // Gray-700
          light: '#6b7280', // Gray-500
        },
        background: {
          light: '#FDF8F3', // Warm cream background
          white: '#FFFFFF',
        },
        surface: {
          DEFAULT: '#FFFFFF',
          light: '#F8F5F2', // Slightly off-white for sections
        },
        text: {
          main: '#1A1A1A',
          muted: '#717171',
          light: '#A3A3A3',
        },
        border: {
          DEFAULT: '#F1E9E2',
        }
      },
      fontFamily: {
        sans: ['Nunito', 'sans-serif'],
        display: ['Outfit', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 20px 40px -15px rgba(234, 88, 12, 0.15)',
        'card': '0 10px 30px -10px rgba(0, 0, 0, 0.04)',
        'premium': '0 25px 50px -12px rgba(0, 0, 0, 0.08)',
      },
      borderRadius: {
        'xl': '1.25rem',
        '2xl': '1.75rem',
        '3xl': '2.5rem',
        'pill': '9999px',
      }
    },
  },
  plugins: [],
}

