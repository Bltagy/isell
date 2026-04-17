export const locales = ["en", "ar"] as const;
export type AppLocale = (typeof locales)[number];

export const defaultLocale: AppLocale = "ar";

export function isRtlLocale(locale: string) {
  return locale === "ar";
}

