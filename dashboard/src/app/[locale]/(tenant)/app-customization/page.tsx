"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useSettings, useUpdateSettings, type AppSettings} from "@/hooks/useSettings";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {Textarea} from "@/components/ui/textarea";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Separator} from "@/components/ui/separator";
import {ColorPickerField} from "@/components/customization/ColorPickerField";
import {PhoneMockup} from "@/components/customization/PhoneMockup";
import {toast} from "sonner";
import {AlertTriangle} from "lucide-react";

const FONTS = ["Cairo", "Tajawal", "Almarai", "Roboto", "Poppins"];

const DEFAULT_SETTINGS: Partial<AppSettings> = {
  app_name_en: "Food App",
  app_name_ar: "تطبيق الطعام",
  primary_color: "#FF6B35",
  secondary_color: "#6366f1",
  accent_color: "#f59e0b",
  background_color: "#ffffff",
  text_color: "#111827",
  font_family: "Cairo",
  maintenance_mode: false,
};

export default function AppCustomizationPage() {
  const t = useTranslations("customization");
  const {data: saved, isLoading} = useSettings();
  const update = useUpdateSettings();

  const [form, setForm] = React.useState<Partial<AppSettings>>(DEFAULT_SETTINGS);
  const [dirty, setDirty] = React.useState(false);

  React.useEffect(() => {
    if (saved) {
      setForm(saved);
      setDirty(false);
    }
  }, [saved]);

  const set = <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => {
    setForm((f) => ({...f, [key]: value}));
    setDirty(true);
  };

  const handlePublish = async () => {
    try {
      await update.mutateAsync(form);
      toast.success("Changes published!");
      setDirty(false);
    } catch {
      toast.error("Failed to save");
    }
  };

  const handleDiscard = () => {
    if (saved) setForm(saved);
    setDirty(false);
  };

  if (isLoading) return <div className="animate-pulse space-y-4"><div className="h-8 bg-muted rounded w-48" /><div className="h-96 bg-muted rounded" /></div>;

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">{t("title")}</h1>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Settings panel */}
        <div className="space-y-4">
          {/* Branding */}
          <Card>
            <CardHeader><CardTitle className="text-base">{t("branding")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div><Label>{t("appNameEn")}</Label><Input value={form.app_name_en ?? ""} onChange={(e) => set("app_name_en", e.target.value)} /></div>
              <div><Label>{t("appNameAr")}</Label><Input dir="rtl" value={form.app_name_ar ?? ""} onChange={(e) => set("app_name_ar", e.target.value)} /></div>
            </CardContent>
          </Card>

          {/* Colors */}
          <Card>
            <CardHeader><CardTitle className="text-base">{t("colors")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <ColorPickerField label={t("primaryColor")} value={form.primary_color ?? "#FF6B35"} onChange={(v) => set("primary_color", v)} />
              <ColorPickerField label={t("secondaryColor")} value={form.secondary_color ?? "#6366f1"} onChange={(v) => set("secondary_color", v)} />
              <ColorPickerField label={t("accentColor")} value={form.accent_color ?? "#f59e0b"} onChange={(v) => set("accent_color", v)} />
              <ColorPickerField label={t("backgroundColor")} value={form.background_color ?? "#ffffff"} onChange={(v) => set("background_color", v)} />
              <ColorPickerField label={t("textColor")} value={form.text_color ?? "#111827"} onChange={(v) => set("text_color", v)} />
            </CardContent>
          </Card>

          {/* Typography */}
          <Card>
            <CardHeader><CardTitle className="text-base">{t("typography")}</CardTitle></CardHeader>
            <CardContent>
              <Label>{t("fontFamily")}</Label>
              <Select value={form.font_family ?? "Cairo"} onValueChange={(v) => set("font_family", v as AppSettings["font_family"])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {FONTS.map((f) => <SelectItem key={f} value={f}>{f}</SelectItem>)}
                </SelectContent>
              </Select>
            </CardContent>
          </Card>

          {/* Content */}
          <Card>
            <CardHeader><CardTitle className="text-base">{t("content")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div><Label>{t("aboutUsEn")}</Label><Textarea value={form.about_us_en ?? ""} onChange={(e) => set("about_us_en", e.target.value)} rows={3} /></div>
              <div><Label>{t("aboutUsAr")}</Label><Textarea dir="rtl" value={form.about_us_ar ?? ""} onChange={(e) => set("about_us_ar", e.target.value)} rows={3} /></div>
              <div><Label>{t("contactPhone")}</Label><Input value={form.contact_phone ?? ""} onChange={(e) => set("contact_phone", e.target.value)} /></div>
              <div><Label>{t("contactEmail")}</Label><Input type="email" value={form.contact_email ?? ""} onChange={(e) => set("contact_email", e.target.value)} /></div>
              <div><Label>{t("appStoreUrl")}</Label><Input value={form.app_store_url ?? ""} onChange={(e) => set("app_store_url", e.target.value)} /></div>
              <div><Label>{t("playStoreUrl")}</Label><Input value={form.play_store_url ?? ""} onChange={(e) => set("play_store_url", e.target.value)} /></div>
            </CardContent>
          </Card>

          {/* Maintenance */}
          <Card className={form.maintenance_mode ? "border-destructive" : ""}>
            <CardHeader><CardTitle className="text-base">{t("maintenance")}</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center gap-3">
                <Switch checked={form.maintenance_mode ?? false} onCheckedChange={(v) => set("maintenance_mode", v)} />
                <Label>{t("maintenanceMode")}</Label>
              </div>
              {form.maintenance_mode && (
                <div className="flex items-start gap-2 rounded-md bg-destructive/10 p-3 text-destructive">
                  <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
                  <p className="text-sm">{t("maintenanceWarning")}</p>
                </div>
              )}
              <div><Label>{t("maintenanceMsgEn")}</Label><Input value={form.maintenance_message_en ?? ""} onChange={(e) => set("maintenance_message_en", e.target.value)} /></div>
              <div><Label>{t("maintenanceMsgAr")}</Label><Input dir="rtl" value={form.maintenance_message_ar ?? ""} onChange={(e) => set("maintenance_message_ar", e.target.value)} /></div>
            </CardContent>
          </Card>
        </div>

        {/* Phone preview - sticky */}
        <div className="lg:sticky lg:top-20 lg:self-start">
          <Card>
            <CardHeader><CardTitle className="text-base text-center">{t("phonePreview")}</CardTitle></CardHeader>
            <CardContent>
              <PhoneMockup
                appName={form.app_name_en ?? "Food App"}
                primaryColor={form.primary_color ?? "#FF6B35"}
                backgroundColor={form.background_color ?? "#ffffff"}
                textColor={form.text_color ?? "#111827"}
                fontFamily={form.font_family ?? "Cairo"}
                logoUrl={form.logo_url}
                maintenanceMode={form.maintenance_mode}
              />
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Sticky action bar */}
      <div className="sticky bottom-0 bg-background border-t py-3 flex gap-3 justify-end">
        <Button variant="outline" onClick={handleDiscard} disabled={!dirty}>
          {t("discardChanges" as never)}
        </Button>
        <Button onClick={handlePublish} disabled={!dirty || update.isPending}>
          {update.isPending ? "Saving..." : t("publishChanges" as never)}
        </Button>
      </div>
    </div>
  );
}
