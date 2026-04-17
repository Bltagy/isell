"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useSettings, useUpdateSettings} from "@/hooks/useSettings";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {Card, CardContent, CardHeader, CardTitle, CardDescription} from "@/components/ui/card";
import {toast} from "sonner";
import {api} from "@/lib/api";
import {Image as ImageIcon} from "lucide-react";

const DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] as const;

export default function SettingsPage() {
  const t = useTranslations("settings");
  const {data: settings, isLoading} = useSettings();
  const update = useUpdateSettings();

  const [delivery, setDelivery] = React.useState({delivery_fee: "", min_order_amount: "", tax_percentage: "", max_delivery_radius: ""});
  const [payment, setPayment] = React.useState({kashier_merchant_id: "", kashier_api_key: "", cod_enabled: true, showKey: false});
  const [fcm, setFcm] = React.useState({fcm_server_key: "", showKey: false});
  const [hours, setHours] = React.useState<Record<string, {open: boolean; from: string; to: string}>>({});
  const [otpEnabled, setOtpEnabled] = React.useState(true);
  const [logos, setLogos] = React.useState<{app_logo?: string; dashboard_logo?: string}>({});
  const [uploading, setUploading] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!settings) return;
    setDelivery({
      delivery_fee: String((settings.delivery_fee ?? 0) / 100),
      min_order_amount: String((settings.min_order_amount ?? 0) / 100),
      tax_percentage: String(settings.tax_percentage ?? 14),
      max_delivery_radius: String(settings.max_delivery_radius ?? 10),
    });
    setPayment((p) => ({...p, kashier_merchant_id: settings.kashier_merchant_id ?? "", kashier_api_key: settings.kashier_api_key ?? "", cod_enabled: settings.cod_enabled ?? true}));
    setFcm((f) => ({...f, fcm_server_key: settings.fcm_server_key ?? ""}));
    const defaultHours = DAYS.reduce((acc, day) => ({...acc, [day]: {open: true, from: "09:00", to: "22:00"}}), {});
    setHours(settings.working_hours ?? defaultHours);
    setOtpEnabled(settings.otp_login_enabled !== false);
    setLogos({app_logo: settings.logo_url, dashboard_logo: settings.dashboard_logo_url});
  }, [settings]);

  const saveDelivery = async () => {
    try { await update.mutateAsync({delivery_fee: Math.round(Number(delivery.delivery_fee)*100), min_order_amount: Math.round(Number(delivery.min_order_amount)*100), tax_percentage: Number(delivery.tax_percentage), max_delivery_radius: Number(delivery.max_delivery_radius)}); toast.success("Saved"); } catch { toast.error("Failed"); }
  };
  const savePayment = async () => {
    try { await update.mutateAsync({kashier_merchant_id: payment.kashier_merchant_id, kashier_api_key: payment.kashier_api_key, cod_enabled: payment.cod_enabled}); toast.success("Saved"); } catch { toast.error("Failed"); }
  };
  const saveHours = async () => {
    try { await update.mutateAsync({working_hours: hours}); toast.success("Saved"); } catch { toast.error("Failed"); }
  };
  const saveFcm = async () => {
    try { await update.mutateAsync({fcm_server_key: fcm.fcm_server_key}); toast.success("Saved"); } catch { toast.error("Failed"); }
  };
  const saveAuth = async () => {
    try { await update.mutateAsync({otp_login_enabled: otpEnabled}); toast.success("Saved"); } catch { toast.error("Failed"); }
  };
  const applyToAll = () => {
    const first = hours[DAYS[0]]; if (!first) return;
    setHours(DAYS.reduce((acc, day) => ({...acc, [day]: {...first}}), {}));
  };
  const uploadLogo = async (key: "app_logo" | "dashboard_logo", file: File) => {
    setUploading(key);
    try {
      const fd = new FormData(); fd.append("key", key); fd.append("image", file);
      const res = await api.post("/api/v1/admin/settings/upload-image", fd);
      const url = (res.data.data as {url: string})?.url;
      setLogos((l) => ({...l, [key]: url}));
      toast.success("Logo uploaded");
    } catch { toast.error("Upload failed"); } finally { setUploading(null); }
  };

  if (isLoading) return <div className="animate-pulse space-y-4"><div className="h-8 bg-muted rounded w-32" /><div className="h-64 bg-muted rounded" /></div>;

  return (
    <div className="space-y-4 max-w-2xl">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <Tabs defaultValue="delivery">
        <TabsList className="flex-wrap h-auto">
          <TabsTrigger value="delivery">{t("delivery")}</TabsTrigger>
          <TabsTrigger value="hours">{t("workingHours")}</TabsTrigger>
          <TabsTrigger value="payment">{t("payment")}</TabsTrigger>
          <TabsTrigger value="auth">{t("authSettings")}</TabsTrigger>
          <TabsTrigger value="logos">{t("logos")}</TabsTrigger>
          <TabsTrigger value="notifications">{t("notificationsTab")}</TabsTrigger>
        </TabsList>

        <TabsContent value="delivery" className="mt-4">
          <Card><CardHeader><CardTitle className="text-base">{t("delivery")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div><Label>{t("deliveryFee")}</Label><Input type="number" step="0.01" value={delivery.delivery_fee} onChange={(e) => setDelivery((d) => ({...d, delivery_fee: e.target.value}))} /></div>
              <div><Label>{t("minOrder")}</Label><Input type="number" step="0.01" value={delivery.min_order_amount} onChange={(e) => setDelivery((d) => ({...d, min_order_amount: e.target.value}))} /></div>
              <div><Label>{t("taxPercentage")}</Label><Input type="number" step="0.1" value={delivery.tax_percentage} onChange={(e) => setDelivery((d) => ({...d, tax_percentage: e.target.value}))} /></div>
              <div><Label>{t("maxRadius")}</Label><Input type="number" value={delivery.max_delivery_radius} onChange={(e) => setDelivery((d) => ({...d, max_delivery_radius: e.target.value}))} /></div>
              <Button onClick={saveDelivery} disabled={update.isPending}>{t("saveSection")}</Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="hours" className="mt-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base">{t("workingHours")}</CardTitle>
              <Button variant="outline" size="sm" onClick={applyToAll}>{t("applyToAll")}</Button>
            </CardHeader>
            <CardContent className="space-y-3">
              {DAYS.map((day) => (
                <div key={day} className="flex items-center gap-3">
                  <Switch checked={hours[day]?.open ?? true} onCheckedChange={(v) => setHours((h) => ({...h, [day]: {...(h[day] ?? {from:"09:00",to:"22:00"}), open: v}}))} />
                  <span className="w-24 text-sm">{t(day as Parameters<typeof t>[0])}</span>
                  <Input type="time" value={hours[day]?.from ?? "09:00"} onChange={(e) => setHours((h) => ({...h, [day]: {...(h[day] ?? {open:true,to:"22:00"}), from: e.target.value}}))} className="w-28" disabled={!hours[day]?.open} />
                  <span className="text-muted-foreground text-sm">–</span>
                  <Input type="time" value={hours[day]?.to ?? "22:00"} onChange={(e) => setHours((h) => ({...h, [day]: {...(h[day] ?? {open:true,from:"09:00"}), to: e.target.value}}))} className="w-28" disabled={!hours[day]?.open} />
                </div>
              ))}
              <Button onClick={saveHours} disabled={update.isPending}>{t("saveSection")}</Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="payment" className="mt-4">
          <Card><CardHeader><CardTitle className="text-base">{t("payment")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div><Label>{t("kashierMerchantId")}</Label><Input value={payment.kashier_merchant_id} onChange={(e) => setPayment((p) => ({...p, kashier_merchant_id: e.target.value}))} /></div>
              <div>
                <Label>{t("kashierApiKey")}</Label>
                <div className="flex gap-2">
                  <Input type={payment.showKey ? "text" : "password"} value={payment.kashier_api_key} onChange={(e) => setPayment((p) => ({...p, kashier_api_key: e.target.value}))} className="flex-1" />
                  <Button type="button" variant="outline" size="sm" onClick={() => setPayment((p) => ({...p, showKey: !p.showKey}))}>{payment.showKey ? "Hide" : "Show"}</Button>
                </div>
              </div>
              <div className="flex items-center gap-2"><Switch checked={payment.cod_enabled} onCheckedChange={(v) => setPayment((p) => ({...p, cod_enabled: v}))} /><Label>{t("codEnabled")}</Label></div>
              <Button onClick={savePayment} disabled={update.isPending}>{t("saveSection")}</Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="auth" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t("authSettings")}</CardTitle>
              <CardDescription>{t("authSettingsDesc")}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between rounded-lg border p-4">
                <div>
                  <p className="font-medium text-sm">{t("otpLoginEnabled")}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">{t("otpLoginDesc")}</p>
                </div>
                <Switch checked={otpEnabled} onCheckedChange={setOtpEnabled} />
              </div>
              {!otpEnabled && (
                <div className="rounded-md bg-amber-50 border border-amber-200 p-3 text-amber-800 text-sm">
                  {t("otpDisabledWarning")}
                </div>
              )}
              <Button onClick={saveAuth} disabled={update.isPending}>{t("saveSection")}</Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="logos" className="mt-4 space-y-4">
          {/* app_logo: square 512×512 — show as a compact square */}
          <LogoUploadCard title={t("appLogo")} description={t("appLogoDesc")} currentUrl={logos.app_logo} uploading={uploading === "app_logo"} onUpload={(f) => uploadLogo("app_logo", f)} aspectClass="h-20 w-20 object-contain" />
          {/* dashboard_logo: wide 320×80 — show in its natural wide proportion */}
          <LogoUploadCard title={t("dashboardLogo")} description={t("dashboardLogoDesc")} currentUrl={logos.dashboard_logo} uploading={uploading === "dashboard_logo"} onUpload={(f) => uploadLogo("dashboard_logo", f)} aspectClass="h-10 w-auto max-w-[200px] object-contain" />
        </TabsContent>

        <TabsContent value="notifications" className="mt-4">
          <Card><CardHeader><CardTitle className="text-base">{t("notificationsTab")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div>
                <Label>{t("fcmServerKey")}</Label>
                <div className="flex gap-2">
                  <Input type={fcm.showKey ? "text" : "password"} value={fcm.fcm_server_key} onChange={(e) => setFcm((f) => ({...f, fcm_server_key: e.target.value}))} className="flex-1" />
                  <Button type="button" variant="outline" size="sm" onClick={() => setFcm((f) => ({...f, showKey: !f.showKey}))}>{fcm.showKey ? "Hide" : "Show"}</Button>
                </div>
              </div>
              <div className="flex gap-2">
                <Button onClick={saveFcm} disabled={update.isPending}>{t("saveSection")}</Button>
                <Button variant="outline">{t("testFcm")}</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

function LogoUploadCard({title, description, currentUrl, uploading, onUpload, aspectClass = "h-16 w-auto max-w-[200px]"}: {
  title: string; description: string; currentUrl?: string; uploading: boolean; onUpload: (f: File) => void;
  /** Tailwind classes controlling the preview image size */
  aspectClass?: string;
}) {
  const inputRef = React.useRef<HTMLInputElement>(null);
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {currentUrl ? (
          <div className="flex items-center gap-4">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={currentUrl}
              alt="logo"
              className={`object-contain rounded border bg-muted/40 p-2 ${aspectClass}`}
            />
            <button type="button" onClick={() => inputRef.current?.click()} disabled={uploading} className="text-sm text-primary underline">
              {uploading ? "Uploading..." : "Replace"}
            </button>
          </div>
        ) : (
          <button type="button" onClick={() => inputRef.current?.click()} disabled={uploading}
            className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-lg text-muted-foreground hover:border-primary hover:text-primary transition-colors">
            <ImageIcon className="h-8 w-8 mb-2" />
            <span className="text-sm">{uploading ? "Uploading..." : "Click to upload"}</span>
          </button>
        )}
        <input ref={inputRef} type="file" accept="image/*" className="hidden"
          onChange={(e) => { const f = e.target.files?.[0]; if (f) onUpload(f); e.target.value = ""; }} />
      </CardContent>
    </Card>
  );
}
