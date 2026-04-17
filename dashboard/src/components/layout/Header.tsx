"use client";

import {Menu, Bell, Sun, Moon} from "lucide-react";
import {useTheme} from "next-themes";
import {Button} from "@/components/ui/button";
import {LanguageSwitcher} from "./LanguageSwitcher";
import {useNotificationStore} from "@/stores/notificationStore";
import {Badge} from "@/components/ui/badge";
import {Breadcrumb} from "./Breadcrumb";

type HeaderProps = {
  onMenuClick: () => void;
};

export function Header({onMenuClick}: HeaderProps) {
  const {theme, setTheme} = useTheme();
  const unreadCount = useNotificationStore((s) => s.unreadCount);

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-4 border-b border-border bg-background/95 backdrop-blur px-4">
      <Button
        variant="ghost"
        size="icon"
        className="lg:hidden"
        onClick={onMenuClick}
        aria-label="Open menu"
      >
        <Menu className="h-5 w-5" />
      </Button>

      <div className="flex-1 min-w-0">
        <Breadcrumb />
      </div>

      <div className="flex items-center gap-1">
        {/* Dark mode toggle */}
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
          aria-label="Toggle theme"
        >
          <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
        </Button>

        {/* Language switcher */}
        <LanguageSwitcher />

        {/* Notifications bell */}
        <Button variant="ghost" size="icon" className="relative" aria-label="Notifications">
          <Bell className="h-4 w-4" />
          {unreadCount > 0 && (
            <Badge
              variant="destructive"
              className="absolute -top-1 -end-1 h-4 min-w-4 px-0.5 text-[10px] flex items-center justify-center"
            >
              {unreadCount > 99 ? "99+" : unreadCount}
            </Badge>
          )}
        </Button>
      </div>
    </header>
  );
}
