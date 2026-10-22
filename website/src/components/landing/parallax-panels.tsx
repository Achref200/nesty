"use client";

import { useEffect, useRef } from "react";

/** Subtle mouse-parallax panels floating behind the hero. Purely decorative. */
export function ParallaxPanels() {
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const panels = wrapRef.current?.querySelectorAll<HTMLElement>("[data-depth]");
    if (!panels || panels.length === 0) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    let tx = 0, ty = 0, cx = 0, cy = 0, raf = 0;
    const onMove = (e: MouseEvent) => {
      tx = (e.clientX / window.innerWidth - 0.5) * 2;
      ty = (e.clientY / window.innerHeight - 0.5) * 2;
    };
    const loop = () => {
      cx += (tx - cx) * 0.06;
      cy += (ty - cy) * 0.06;
      panels.forEach((p) => {
        const d = parseFloat(p.dataset.depth || "0.2");
        const rot = p.dataset.rot || "0";
        p.style.transform = `translate(${cx * d * -40}px, ${cy * d * -40}px) rotate(${rot}deg)`;
      });
      raf = requestAnimationFrame(loop);
    };
    window.addEventListener("mousemove", onMove);
    raf = requestAnimationFrame(loop);
    return () => {
      window.removeEventListener("mousemove", onMove);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <div
      ref={wrapRef}
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 -z-10 hidden md:block"
    >
      <div
        data-depth="0.20"
        data-rot="6"
        className="absolute right-[4%] top-16 h-[150px] w-[210px] rotate-6 rounded-3xl border border-separator bg-card shadow-soft"
      />
      <div
        data-depth="0.35"
        data-rot="-8"
        className="absolute right-[20%] top-56 h-[200px] w-[150px] -rotate-6 rounded-3xl bg-ink shadow-soft"
      />
      <div
        data-depth="0.12"
        data-rot="-4"
        className="absolute right-[2%] top-72 h-[120px] w-[120px] -rotate-3 rounded-3xl border border-separator bg-card shadow-soft"
      />
    </div>
  );
}
