"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery, useMutation} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {Card, CardContent} from "@/components/ui/card";
import {DataTable, type Column} from "@/components/common/DataTable";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {BilingualInput} from "@/components/common/BilingualInput";
import {toast} from "sonner";
import {Bell} from "lucide-react";
import {format} from "date-fns";

type NotifHistory = {id: number; title_en: string; target: string; sent_at: string; sent_count: number; failed_count: number};

type FormState = {
  target: string; user_id: string;
  title_en: string; title_ar: string;
  body_en: string; body_ar: string;
  schedule: string; scheduled_at: string;
};

const DEFAULT_FORM: FormState = {target: "all", user_id: "", title_en: "", title_ar: "", body_en: "", body_ar: "", schedule: "now", scheduled_at: ""};

export default function NotificationsPage() {
  const t = useTranslations("notifications");
  const [form, setForm] = React.useState<FormState>(DEFAULT_FORM);
  const [confirmOpen, setConfirmOpen] = React.useState(false);

  const {data: history, isLoading} = useQuery<NotifHistory[]>({
    queryKey: ["notifications-history"],
    queryFn: async () => {
      const res = await api.get<{data: NotifHistory[]}>("/api/v1/admin/notifications");
      return res.data.data ?? [];
    },
  });

  const send = useMutation({
    mutationFn: async () => {
      await api.post("/api/v1/admin/notifications/broadcast", {
        ...form,
        user_id: form.target === "specific" ? Number(form.user_id) : undefined,
        scheduled_at: form.schedule === "later" ? form.scheduled_at : undefined,
      });
    },
    onSuccess: () => {toast.success("Notification sent!"); setForm(DEFAULT_FORM); setConfirmOpen(false);},
    onError: () => toast.error("Failed to send"),
  });

  const historyColumns: Column<NotifHistory>[] = [
    {key: "title", header: "Title", cell: (row) => row.title_en},
    {key: "target", header: t("target"), cell: (row) => row.target},
    {key: "sent_at", header: t("sentAt"), cell: (row) => format(new Date(row.sent_at), "dd/MM/yyyy HH:mm"), className: "hidden sm:table-cell"},
    {key: "stats", header: t("deliveryStats"), cell: (row) => <span className="text-xs">{row.sent_count} sent / {row.failed_count} failed</span>},
  ];

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <Tabs defaultValue="send">
        <TabsList>
          <TabsTrigger value="send">{t("send")}</TabsTrigger>
          <TabsTrigger value="history">{t("history")}</TabsTrigger>
        </TabsList>

        <TabsContent value="send" className="mt-4">
          <div className="grid gap-4 lg:grid-cols-2">
            <div className="space-y-4">
              <div><Label>{t("target")}</Label>
                <Select value={form.target} onValueChange={(v) => setForm((f) => ({...f, target: v ?? "all"}))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">{t("allUsers")}</SelectItem>
                    <SelectItem value="specific">{t("specificUser")}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              {form.target === "specific" && <div><Label>{t("selectUser")}</Label><Input type="number" placeholder="User ID" value={form.user_id} onChange={(e) => setForm((f) => ({...f, user_id: e.target.value}))} /></div>}
              <div><Label>Title</Label><BilingualInput valueEn={form.title_en} valueAr={form.title_ar} onChangeEn={(v) => setForm((f) => ({...f, title_en: v}))} onChangeAr={(v) => setForm((f) => ({...f, title_ar: v}))} /></div>
              <div><Label>Body</Label><BilingualInput multiline valueEn={form.body_en} valueAr={form.body_ar} onChangeEn={(v) => setForm((f) => ({...f, body_en: v}))} onChangeAr={(v) => setForm((f) => ({...f, body_ar: v}))} /></div>
              <div><Label>{t("schedule")}</Label>
                <Select value={form.schedule} onValueChange={(v) => setForm((f) => ({...f, schedule: v ?? "now"}))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="now">{t("now")}</SelectItem>
                    <SelectItem value="later">{t("later")}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              {form.schedule === "later" && <div><Label>{t("scheduledAt")}</Label><Input type="datetime-local" value={form.scheduled_at} onChange={(e) => setForm((f) => ({...f, scheduled_at: e.target.value}))} /></div>}
              <Button onClick={() => setConfirmOpen(true)} className="gap-2 w-full"><Bell className="h-4 w-4" />{t("sendButton")}</Button>
            </div>

            {/* Preview */}
            <div>
              <Label>{t("preview")}</Label>
              <Card className="mt-2">
                <CardContent className="pt-4">
                  <div className="flex items-start gap-3">
                    <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                      <Bell className="h-5 w-5 text-primary" />
                    </div>
                    <div>
                      <p className="font-semibold text-sm">{form.title_en || "Notification Title"}</p>
                      <p className="text-sm text-muted-foreground mt-1">{form.body_en || "Notification body text will appear here."}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="history" className="mt-4">
          <DataTable columns={historyColumns} data={history ?? []} isLoading={isLoading} emptyMessage={t("noHistory")} rowKey={(row) => row.id} />
        </TabsContent>
      </Tabs>

      <ConfirmDialog open={confirmOpen} onOpenChange={setConfirmOpen} title="Send Notification" description={t("confirmSend")} confirmLabel={t("sendButton")} variant="default" onConfirm={() => send.mutate()} />
    </div>
  );
}
