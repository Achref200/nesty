"use client";

import { useEffect, useState } from "react";

/**
 * A cozy typewriter reveal. The full text is passed in and also rendered by the
 * server for SEO/accessibility; this component re-types it on the client for a
 * warm first impression.
 */
export function TypingHeadline({
  text,
  startDelay = 350,
  className,
}: {
  text: string;
  startDelay?: number;
  className?: string;
}) {
  const [count, setCount] = useState(0);
  const [done, setDone] = useState(false);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    let i = 0;
    const tick = () => {
      if (i > text.length) {
        setDone(true);
        return;
      }
      setCount(i);
      const ch = text[i - 1];
      i += 1;
      timer = setTimeout(tick, ch === "." ? 300 : 52);
    };
    const start = setTimeout(tick, startDelay);
    return () => {
      clearTimeout(start);
      clearTimeout(timer);
    };
  }, [text, startDelay]);

  return (
    <span className={className}>
      {text.slice(0, count)}
      {!done && <span className="caret" aria-hidden="true" />}
      {/* Full text for crawlers & screen readers, visually hidden. */}
      <span className="sr-only">{text}</span>
    </span>
  );
}
