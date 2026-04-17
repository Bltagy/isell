"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {DataTable, type Column} from "@/components/common/DataTable";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter} from "@/components/ui/dialog";
import {Badge} from "@/components/ui/badge";
import {toast} from "sonner";
import {Plus, Pencil, Trash2, RefreshCw} from "lucide-react";
import {format} from "date-fns";

type Offer = {
  id: number; code: string; type: string; value: number;
  min_order_amount: number; usage_count: number; usage_limit?: number;
  start_date: string; end_date: string; is_active: boolean;
};

type FormState = {
  code: string; type: string; value: string; min_order_amount: string;
  max_discount_amount: string; start_date: string; end_date: string;
  usage_limit: string; unlimited: boolean; is_active: boolean;
};

const DEFAULT_FORM: FormState = {
  code: "", type: "percentage", value: "", min_order_amount: "",
  max_discount_amount: "", start_date: "", end_date: "",
  usage_limit: "", unlimited: true, is_active: true,
};

function generateCode() {
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}

export default function OffersPage() {
  const t = useTranslations("offers");
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = React.useState(false);
  const [editId, setEditId] = React.useState<number | null>(null);
  const [form, setForm] = React.useState<FormState>(DEFAULT_FORM);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data: offers, isLoading} = useQuery<Offer[]>({
    queryKey: ["offers"],
    queryFn: async () => {
      const res = await api.get<{data: Offer[]}>("/api/v1/admin/offers");
      return res.data.data ?? [];
    },
  });

  const save = useMutation({
    mutationFn: async (payload: object) => {
      if (editId) return api.put(`/api/v1/admin/offers/${editId}`, payload);
      return api.post("/api/v1/admin/offers", payload);
    },
    onSuccess: () => {qc.invalidateQueries({queryKey: ["offers"]}); toast.success("Saved"); setModalOpen(false);},
    onError: () => toast.error("Failed"),
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/offers/${id}`),
    onSuccess: () => {qc.invalidateQueries({queryKey: ["offers"]}); toast.success("Deleted"); setDeleteId(null);},
    onError: () => toast.error("Failed"),
  });

  const openAdd = () => {setEditId(null); setForm(DEFAULT_FORM); setModalOpen(true);};
  const openEdit = (o: Offer) => {
    setEditId(o.id);
    setForm({code: o.code, type: o.type, value: String(o.value), min_order_amount: String(o.min_order_amount / 100), max_discount_amount: "", start_date: o.start_date?.slice(0, 10) ?? "", end_date: o.end_date?.slice(0, 10) ?? "", usage_limit: o.usage_limit?.toString() ?? "", unlimited: !o.usage_limit, is_active: o.is_active});
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    save.mutate({
      ...form,
      value: Number(form.value),
      min_order_amount: Math.round(Number(form.min_order_amount) * 100),
      max_discount_amount: form.max_discount_amount ? Math.round(Number(form.max_discount_amount) * 100) : null,
      usage_limit: form.unlimited ? null : Number(form.usage_limit),
    });
  };

  const columns: Column<Offer>[] = [
    {key: "code", header: t("code"), cell: (row) => <span className="font-mono font-semibold">{row.code}</span>},
    {key: "type", header: t("type"), cell: (row) => <Badge variant="outline">{row.type}</Badge>},
    {key: "value", header: t("value"), cell: (row) => row.type === "percentage" ? `${row.value}%` : row.type === "free_delivery" ? "Free" : `${(row.value / 100).toFixed(2)} EGP`},
    {key: "usage", header: "Usage", cell: (row) => `${row.usage_count}${row.usage_limit ? `/${row.usage_limit}` : ""}`, className: "hidden sm:table-cell"},
    {key: "dates", header: "Validity", cell: (row) => <span className="text-xs">{format(new Date(row.start_date), "dd/MM")} – {format(new Date(row.end_date), "dd/MM/yy")}</span>, className: "hidden md:table-cell"},
    {key: "active", header: t("isActive"), cell: (row) => <Switch checked={row.is_active} onCheckedChange={(v) => save.mutate({is_active: v})} />},
    {key: "actions", header: "", cell: (row) => (
      <div className="flex gap-1">
        <Button variant="ghost" size="icon" onClick={() => openEdit(row)}><Pencil className="h-4 w-4" /></Button>
        <Button variant="ghost" size="icon" onClick={() => setDeleteId(row.id)} className="text-destructive hover:text-destructive"><Trash2 className="h-4 w-4" /></Button>
      </div>
    )},
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t("title")}</h1>
        <Button onClick={openAdd} className="gap-2"><Plus className="h-4 w-4" />{t("addOffer")}</Button>
      </div>
      <DataTable columns={columns} data={offers ?? []} isLoading={isLoading} emptyMessage={t("noOffers")} rowKey={(row) => row.id} />

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>{editId ? t("editOffer") : t("addOffer")}</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="flex gap-2">
              <div className="flex-1"><Label>{t("code")}</Label><Input value={form.code} onChange={(e) => setForm((f) => ({...f, code: e.target.value}))} required /></div>
              <div className="flex items-end"><Button type="button" variant="outline" size="icon" onClick={() => setForm((f) => ({...f, code: generateCode()}))} aria-label="Generate"><RefreshCw className="h-4 w-4" /></Button></div>
            </div>
            <div><Label>{t("type")}</Label>
              <Select value={form.type} onValueChange={(v) => setForm((f) => ({...f, type: v ?? ""}))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="percentage">{t("percentage")}</SelectItem>
                  <SelectItem value="fixed">{t("fixedAmount")}</SelectItem>
                  <SelectItem value="free_delivery">{t("freeDelivery")}</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {form.type !== "free_delivery" && <div><Label>{t("value")}</Label><Input type="number" step="0.01" value={form.value} onChange={(e) => setForm((f) => ({...f, value: e.target.value}))} required /></div>}
            <div className="grid grid-cols-2 gap-3">
              <div><Label>{t("minOrder")}</Label><Input type="number" step="0.01" value={form.min_order_amount} onChange={(e) => setForm((f) => ({...f, min_order_amount: e.target.value}))} /></div>
              {form.type === "percentage" && <div><Label>{t("maxDiscount")}</Label><Input type="number" step="0.01" value={form.max_discount_amount} onChange={(e) => setForm((f) => ({...f, max_discount_amount: e.target.value}))} /></div>}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div><Label>{t("startDate")}</Label><Input type="date" value={form.start_date} onChange={(e) => setForm((f) => ({...f, start_date: e.target.value}))} required /></div>
              <div><Label>{t("endDate")}</Label><Input type="date" value={form.end_date} onChange={(e) => setForm((f) => ({...f, end_date: e.target.value}))} required /></div>
            </div>
            <div className="flex items-center gap-2"><Switch checked={form.unlimited} onCheckedChange={(v) => setForm((f) => ({...f, unlimited: v}))} /><Label>{t("unlimited")}</Label></div>
            {!form.unlimited && <div><Label>{t("usageLimit")}</Label><Input type="number" value={form.usage_limit} onChange={(e) => setForm((f) => ({...f, usage_limit: e.target.value}))} /></div>}
            <div className="flex items-center gap-2"><Switch checked={form.is_active} onCheckedChange={(v) => setForm((f) => ({...f, is_active: v}))} /><Label>{t("isActive")}</Label></div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={save.isPending}>Save</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)} title="Delete Offer" description="Are you sure?" onConfirm={() => deleteId && remove.mutate(deleteId)} />
    </div>
  );
}
