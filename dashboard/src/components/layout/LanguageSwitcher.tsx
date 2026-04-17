"use client";

import {useLocale} from "next-intl";
import Link from "next/link";
import {usePathname} from "next/navigation";

import {buttonVariants} from "@/components/ui/button";
import {locales, type AppLocale} from "@/i18n/routing";

function switchLocalePath(pathname: string, nextLocale: AppLocale) {
  const parts = pathname.split("/");
  if (parts.length >= 2 && locales.includes(parts[1] as AppLocale)) {
    parts[1] = nextLocale;
    return parts.join("/") || `/${nextLocale}`;
  }
  return `/${nextLocale}${pathname.startsWith("/") ? "" : "/"}${pathname}`;
}

export function LanguageSwitcher() {
  const locale = useLocale() as AppLocale;
  const pathname = usePathname();
  const nextLocale: AppLocale = locale === "ar" ? "en" : "ar";

  return (
    <Link
      aria-label="Switch language"
      className={buttonVariants({variant: "ghost", size: "sm"})}
      href={switchLocalePath(pathname, nextLocale)}
      prefetch={false}
    >
      {nextLocale.toUpperCase()}
    </Link>
  );
}

