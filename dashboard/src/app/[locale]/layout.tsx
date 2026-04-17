import {locales} from "@/i18n/routing";

export function generateStaticParams() {
  return locales.map((locale) => ({locale}));
}

export default function LocaleLayout({children}: {children: React.ReactNode}) {
  return children;
}

