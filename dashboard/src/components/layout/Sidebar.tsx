"use client";

import {useLocale, useTranslations} from "next-intl";
import Link from "next/link";
import {usePathname, useRouter} from "next/navigation";
import {
  LayoutDashboard,
  ShoppingBag,
  Grid,
  UtensilsCrossed,
  Users,
  Bike,
  Tag,
  Image,
  Bell,
  Palette,
  BarChart3,
  Settings,
  ChevronDown,
  LogOut,
  X,
} from "lucide-react";
import {cn} from "@/lib/utils";
import {useNotificationStore} from "@/stores/notificationStore";
import {useAuthStore} from "@/stores/authStore";
import {Badge} from "@/components/ui/badge";
import {Button} from "@/components/ui/button";
import {Avatar, AvatarFallback} from "@/components/ui/avatar";
import {api} from "@/lib/api";
import {clearToken} from "@/lib/auth";
import {toast} from "sonner";
import React from "react";
import {useSettings} from "@/hooks/useSettings";

type NavItem = {
  key: string;
  href: string;
  icon: React.ElementType;
  badge?: number;
  children?: {key: string; href: string; icon: React.ElementType}[];
};

type SidebarProps = {
  open: boolean;
  onClose: () => void;
};

export function Sidebar({open, onClose}: SidebarProps) {
  const t = useTranslations("nav");
  const locale = useLocale();
  const pathname = usePathname();
  const router = useRouter();
  const {user, clearAuth} = useAuthStore();
  const pendingOrders = useNotificationStore((s) => s.pendingOrdersCount);
  const [menuOpen, setMenuOpen] = React.useState(false);
  const {data: settings} = useSettings();
  const logoSrc = settings?.dashboard_logo_url || "/logo.svg";

  const base = `/${locale}`;

  const navItems: NavItem[] = [
    {key: "dashboard", href: `${base}/dashboard`, icon: LayoutDashboard},
    {
      key: "orders",
      href: `${base}/orders`,
      icon: ShoppingBag,
      badge: pendingOrders > 0 ? pendingOrders : undefined,
    },
    {
      key: "menu",
      href: `${base}/menu/categories`,
      icon: UtensilsCrossed,
      children: [
        {key: "categories", href: `${base}/menu/categories`, icon: Grid},
        {key: "products", href: `${base}/menu/products`, icon: UtensilsCrossed},
      ],
    },
    {key: "customers", href: `${base}/customers`, icon: Users},
    {key: "drivers", href: `${base}/drivers`, icon: Bike},
    {key: "offers", href: `${base}/offers`, icon: Tag},
    {key: "banners", href: `${base}/banners`, icon: Image},
    {key: "notifications", href: `${base}/notifications`, icon: Bell},
    {key: "appCustomization", href: `${base}/app-customization`, icon: Palette},
    {key: "analytics", href: `${base}/analytics`, icon: BarChart3},
    {key: "settings", href: `${base}/settings`, icon: Settings},
  ];

  const isActive = (href: string) => pathname === href || pathname.startsWith(href + "/");

  const handleLogout = async () => {
    try {
      await api.post("/api/v1/auth/logout");
    } catch {
      // ignore — still log out locally
    }
    clearAuth();
    clearToken();
    router.replace(`/${locale}/login`);
    toast.success("Logged out");
  };

  const initials = user?.name
    ? user.name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .toUpperCase()
        .slice(0, 2)
    : "AD";

  return (
    <>
      {/* Overlay for mobile */}
      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/50 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 z-40 flex w-64 flex-col bg-card border-e border-border transition-transform duration-300 lg:static lg:translate-x-0",
          open ? "translate-x-0" : "-translate-x-full",
          "rtl:translate-x-0 rtl:data-[open=false]:-translate-x-full"
        )}
        data-open={open}
        aria-label="Sidebar navigation"
      >
        {/* Header */}
        <div className="flex h-16 items-center justify-between px-4 border-b border-border">
          <Link href={`${base}/dashboard`} className="flex items-center gap-2 font-bold text-primary text-lg">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={logoSrc} alt="FoodApp" className="h-8 w-auto" />
          </Link>
          <Button variant="ghost" size="icon" className="lg:hidden" onClick={onClose} aria-label="Close sidebar">
            <X className="h-4 w-4" />
          </Button>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-1" aria-label="Main navigation">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.href);

            if (item.children) {
              return (
                <div key={item.key}>
                  <button
                    onClick={() => setMenuOpen((p) => !p)}
                    className={cn(
                      "flex w-full items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                      active
                        ? "bg-primary/10 text-primary"
                        : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                    )}
                    aria-expanded={menuOpen}
                  >
                    <Icon className="h-4 w-4 shrink-0" />
                    <span className="flex-1 text-start">{t(item.key as Parameters<typeof t>[0])}</span>
                    <ChevronDown className={cn("h-3 w-3 transition-transform", menuOpen && "rotate-180")} />
                  </button>
                  {menuOpen && (
                    <div className="ms-4 mt-1 space-y-1 border-s border-border ps-3">
                      {item.children.map((child) => {
                        const ChildIcon = child.icon;
                        const childActive = isActive(child.href);
                        return (
                          <Link
                            key={child.key}
                            href={child.href}
                            onClick={onClose}
                            className={cn(
                              "flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors",
                              childActive
                                ? "bg-primary/10 text-primary font-medium"
                                : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                            )}
                          >
                            <ChildIcon className="h-4 w-4 shrink-0" />
                            {t(child.key as Parameters<typeof t>[0])}
                          </Link>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            }

            return (
              <Link
                key={item.key}
                href={item.href}
                onClick={onClose}
                className={cn(
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  active
                    ? "bg-primary/10 text-primary"
                    : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                )}
                aria-current={active ? "page" : undefined}
              >
                <Icon className="h-4 w-4 shrink-0" />
                <span className="flex-1">{t(item.key as Parameters<typeof t>[0])}</span>
                {item.badge ? (
                  <Badge variant="destructive" className="h-5 min-w-5 px-1 text-xs">
                    {item.badge > 99 ? "99+" : item.badge}
                  </Badge>
                ) : null}
              </Link>
            );
          })}
        </nav>

        {/* User footer */}
        <div className="border-t border-border p-3">
          <div className="flex items-center gap-3">
            <Avatar className="h-8 w-8">
              <AvatarFallback className="bg-primary/10 text-primary text-xs">{initials}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.name ?? "Admin"}</p>
              <p className="text-xs text-muted-foreground truncate">{user?.email ?? ""}</p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleLogout}
              aria-label="Logout"
              className="shrink-0 text-muted-foreground hover:text-destructive"
            >
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </aside>
    </>
  );
}
