"use client";

import {useTranslations} from "next-intl";
import {usePathname} from "next/navigation";
import Link from "next/link";
import {ChevronRight} from "lucide-react";
import {cn} from "@/lib/utils";

const segmentToKey: Record<string, string> = {
  dashboard: "dashboard",
  orders: "orders",
  menu: "menu",
  categories: "categories",
  products: "products",
  customers: "customers",
  drivers: "drivers",
  offers: "offers",
  banners: "banners",
  notifications: "notifications",
  "app-customization": "appCustomization",
  analytics: "analytics",
  settings: "settings",
};

export function Breadcrumb() {
  const t = useTranslations("nav");
  const pathname = usePathname();

  const parts = pathname.split("/").filter(Boolean);
  // Remove locale prefix
  const segments = parts.slice(1);

  if (segments.length === 0) return null;

  const crumbs = segments.map((seg, i) => {
    const href = "/" + parts.slice(0, i + 2).join("/");
    const label = segmentToKey[seg] ? t(segmentToKey[seg] as Parameters<typeof t>[0]) : seg;
    const isLast = i === segments.length - 1;
    return {href, label, isLast};
  });

  return (
    <nav aria-label="Breadcrumb" className="flex items-center gap-1 text-sm">
      {crumbs.map((crumb, i) => (
        <span key={crumb.href} className="flex items-center gap-1">
          {i > 0 && <ChevronRight className="h-3 w-3 text-muted-foreground rtl:rotate-180" />}
          {crumb.isLast ? (
            <span className="font-medium text-foreground">{crumb.label}</span>
          ) : (
            <Link
              href={crumb.href}
              className={cn("text-muted-foreground hover:text-foreground transition-colors")}
            >
              {crumb.label}
            </Link>
          )}
        </span>
      ))}
    </nav>
  );
}
