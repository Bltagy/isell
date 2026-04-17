import createMiddleware from "next-intl/middleware";
import {NextResponse, type NextRequest} from "next/server";
import {defaultLocale, locales} from "./i18n/routing";

const intlMiddleware = createMiddleware({
  locales,
  defaultLocale,
  localePrefix: "always",
});

const AUTH_COOKIE_NAME = "token";

const publicRoutes = new Set(["/login", "/forgot-password"]);
const protectedPrefixes = [
  "/dashboard",
  "/orders",
  "/menu",
  "/customers",
  "/drivers",
  "/offers",
  "/banners",
  "/notifications",
  "/app-customization",
  "/analytics",
  "/settings",
  "/tenants",
  "/plans",
];

export default function middleware(req: NextRequest) {
  const res = intlMiddleware(req);

  // If next-intl decided to redirect (e.g. add missing locale), respect it.
  if (res.headers.get("location")) return res;

  const {pathname} = req.nextUrl;
  const [, locale, ...rest] = pathname.split("/");
  const pathAfterLocale = `/${rest.join("/")}`.replace(/\/$/, "") || "/";

  const isPublicRoute = publicRoutes.has(pathAfterLocale);
  const isProtectedRoute = protectedPrefixes.some((p) => pathAfterLocale === p || pathAfterLocale.startsWith(`${p}/`));

  const token = req.cookies.get(AUTH_COOKIE_NAME)?.value;
  const isAuthenticated = Boolean(token);

  if (!isAuthenticated && isProtectedRoute) {
    const url = req.nextUrl.clone();
    url.pathname = `/${locale}/login`;
    url.searchParams.set("next", pathAfterLocale);
    return NextResponse.redirect(url);
  }

  if (isAuthenticated && isPublicRoute) {
    const url = req.nextUrl.clone();
    url.pathname = `/${locale}/dashboard`;
    return NextResponse.redirect(url);
  }

  return res;
}

export const config = {
  matcher: ["/((?!api|_next|.*\\..*).*)"],
};

