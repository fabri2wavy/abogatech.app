import Image from "next/image";
import styles from "./Brand.module.css";

export function Brand({ light = false, compact = false }: { light?: boolean; compact?: boolean }) {
  return (
    <span className={`${styles.brand} ${light ? styles.light : ""}`} aria-label="ABOGATECH">
      <span className={styles.symbol} aria-hidden="true">
        <Image src="/brand/abogatech-logo.png" alt="" width={96} height={96} className={styles.image} />
      </span>
      {!compact && (
        <span className={styles.wordmark} aria-hidden="true">
          <span>ABOGA<span className={styles.tech}>TECH</span></span>
          <span className={styles.tagline}>GESTIÓN LEGAL INTELIGENTE</span>
        </span>
      )}
    </span>
  );
}
