"use client";

import {useLocale} from "next-intl";

type MoneyDisplayProps = {
  /** Amount in piastres (1 EGP = 100 piastres) */
  piastres: number;
  showSymbol?: boolean;
  className?: string;
};

export function MoneyDisplay({piastres, showSymbol = true, className}: MoneyDisplayProps) {
  const locale = useLocale();
  const egp = piastres / 100;
  const formatted = egp.toFixed(2);

  if (!showSymbol) return <span className={className}>{formatted}</span>;

  if (locale === "ar") {
    return (
      <span className={className} dir="ltr">
        {formatted} ج.م
      </span>
    );
  }

  return <span className={className}>EGP {formatted}</span>;
}
