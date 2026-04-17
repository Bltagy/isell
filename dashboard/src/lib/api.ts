import axios, {AxiosError} from "axios";

type ApiErrorPayload = {
  message?: string;
  errors?: Record<string, string[]>;
};

export type ApiError = {
  message: string;
  status?: number;
  fieldErrors?: Record<string, string[]>;
};

function getToken() {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem("token");
}

function getLocale() {
  if (typeof window === "undefined") return "ar";
  const seg = window.location.pathname.split("/")[1];
  return seg === "en" || seg === "ar" ? seg : "ar";
}

/**
 * Always read at call-time so we pick up window.__ENV__ after it loads.
 * Falls back to build-time process.env, then to localhost.
 */
export function getApiBaseUrl(): string {
  if (typeof window !== "undefined") {
    const w = window as unknown as {__ENV__?: Record<string, string>};
    if (w.__ENV__?.NEXT_PUBLIC_API_URL) return w.__ENV__.NEXT_PUBLIC_API_URL;
  }
  return process.env.NEXT_PUBLIC_API_URL ?? "http://localhost";
}

// Create with no baseURL — it is resolved per-request in the interceptor below
export const api = axios.create({
  headers: { Accept: "application/json" },
});

// Resolve baseURL dynamically on every request
api.interceptors.request.use((config) => {
  if (!config.baseURL) {
    config.baseURL = getApiBaseUrl();
  }

  const token = getToken();
  if (token) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${token}`;
  }

  config.headers = config.headers ?? {};
  config.headers["Accept-Language"] = getLocale();

  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiErrorPayload>) => {
    const status = error.response?.status;

    if (status === 401 && typeof window !== "undefined") {
      const locale = getLocale();
      window.location.href = `/${locale}/login`;
    }

    const payload = error.response?.data;
    const normalized: ApiError = {
      status,
      message:
        payload?.message ||
        error.message ||
        (typeof window !== "undefined" && getLocale() === "ar"
          ? "حصل خطأ. حاول تاني."
          : "Something went wrong. Please try again."),
      fieldErrors: payload?.errors,
    };

    return Promise.reject(normalized);
  }
);
