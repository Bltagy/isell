import type {Metadata} from "next";
import {NextIntlClientProvider} from "next-intl";
import {getLocale, getMessages} from "next-intl/server";
import {ThemeProvider} from "next-themes";
import {Cairo} from "next/font/google";
import Script from "next/script";

import {Toaster} from "@/components/ui/sonner";
import {QueryProvider} from "@/components/providers/QueryProvider";
import {isRtlLocale} from "@/i18n/routing";

import "./globals.css";

const cairo = Cairo({
  subsets: ["latin", "arabic"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Admin Dashboard",
  description: "Multi-tenant food ordering admin dashboard",
};

export default async function RootLayout({children}: {children: React.ReactNode}) {
  const locale = await getLocale();
  const messages = await getMessages();

  return (
    <html lang={locale} dir={isRtlLocale(locale) ? "rtl" : "ltr"} suppressHydrationWarning className={cairo.variable}>
      <head>
        {/* Runtime env — written by docker-entrypoint.sh at container start */}
        <Script src="/__env.js" strategy="beforeInteractive" />
      </head>
      <body className="min-h-screen bg-background font-sans text-foreground antialiased">
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <NextIntlClientProvider locale={locale} messages={messages}>
            <QueryProvider>
              {children}
              <Toaster richColors closeButton />
            </QueryProvider>
          </NextIntlClientProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}

