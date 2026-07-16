import type { Config } from "tailwindcss";

/**
 * Nesty design tokens — a strict black / white / grey monochrome system shared
 * with the mobile app. Ink is the only accent; greys carry all hierarchy.
 */
const config: Config = {
  content: ["./src/**/*.{ts,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        paper: "#FCFCFB",
        card: "#FFFFFF",
        fill: "#F1F1F0",
        ink: { DEFAULT: "#141414", soft: "#3C3C3B" },
        separator: "#E6E6E4",
        muted: { DEFAULT: "#7A7A78", soft: "#B4B4B1" },
        danger: "#B23A34",
      },
      fontFamily: {
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
      },
      borderRadius: {
        pill: "999px",
        "2xl": "20px",
        "3xl": "24px",
      },
      boxShadow: {
        soft: "0 30px 60px -30px rgba(0,0,0,0.18)",
        card: "0 1px 2px rgba(0,0,0,0.04)",
      },
      maxWidth: {
        content: "1080px",
      },
      keyframes: {
        "fade-up": {
          from: { opacity: "0", transform: "translateY(22px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        blink: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0" },
        },
        "scale-in": {
          from: { opacity: "0", transform: "scale(0.96)" },
          to: { opacity: "1", transform: "scale(1)" },
        },
      },
      animation: {
        "fade-up": "fade-up 0.7s cubic-bezier(0.22,1,0.36,1) both",
        blink: "blink 1s steps(1) infinite",
        "scale-in": "scale-in 0.5s cubic-bezier(0.22,1,0.36,1) both",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
