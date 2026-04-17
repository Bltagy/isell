import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api, getApiBaseUrl} from "@/lib/api";

export type AppSettings = {
  app_name_en: string;
  app_name_ar: string;
  logo_url?: string;
  dashboard_logo_url?: string;
  splash_url?: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  background_color: string;
  text_color: string;
  font_family: string;
  about_us_en?: string;
  about_us_ar?: string;
  contact_phone?: string;
  contact_email?: string;
  app_store_url?: string;
  play_store_url?: string;
  maintenance_mode: boolean;
  maintenance_message_en?: string;
  maintenance_message_ar?: string;
  delivery_fee: number;
  min_order_amount: number;
  tax_percentage: number;
  max_delivery_radius: number;
  working_hours?: Record<string, {open: boolean; from: string; to: string}>;
  kashier_merchant_id?: string;
  kashier_api_key?: string;
  cod_enabled: boolean;
  fcm_server_key?: string;
  otp_login_enabled: boolean;
};

/** Resolve a stored image value to a displayable URL.
 *  - Already absolute (http/https) → return as-is
 *  - Relative path (/storage/...) → prepend API base URL
 *  - Empty / null → return undefined
 */
function resolveImageUrl(value: unknown): string | undefined {
  if (!value || typeof value !== "string" || value.trim() === "") return undefined;
  if (value.startsWith("http://") || value.startsWith("https://")) return value;
  return getApiBaseUrl().replace(/\/$/, "") + value;
}

export function useSettings() {
  return useQuery<AppSettings>({
    queryKey: ["settings"],
    queryFn: async () => {
      const res = await api.get<{data: Record<string, {value: unknown}>}>("/api/v1/admin/settings");
      const raw = res.data.data as Record<string, {value: unknown} | unknown>;
      const flat: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(raw)) {
        flat[k] = v && typeof v === "object" && "value" in (v as object) ? (v as {value: unknown}).value : v;
      }

      // Resolve image URLs (handles both relative paths and legacy absolute URLs)
      flat.logo_url           = resolveImageUrl(flat.logo_url);
      flat.dashboard_logo_url = resolveImageUrl(flat.dashboard_logo_url);
      flat.splash_url         = resolveImageUrl(flat.splash_url);

      return flat as unknown as AppSettings;
    },
  });
}

export function useUpdateSettings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: Partial<AppSettings>) => {
      const res = await api.post("/api/v1/admin/settings/batch-update", {settings: data});
      return res.data;
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["settings"]});
    },
  });
}
