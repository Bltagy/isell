/**
 * Auth utilities for client-side token management.
 * Token is stored in localStorage and also set as a cookie
 * so the middleware can read it for route protection.
 */

const TOKEN_KEY = "token";
const COOKIE_NAME = "token";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(TOKEN_KEY, token);
  // Also set as cookie so middleware can read it
  document.cookie = `${COOKIE_NAME}=${token}; path=/; SameSite=Lax`;
}

export function clearToken(): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem(TOKEN_KEY);
  document.cookie = `${COOKIE_NAME}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
}

export function isAuthenticated(): boolean {
  return !!getToken();
}
