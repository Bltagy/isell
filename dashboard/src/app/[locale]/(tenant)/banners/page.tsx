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
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter} from "@/components/ui/dialog";
import {BilingualInput} from "@/components/common/BilingualInput";
import {toast} from "sonner";
import {Plus, Pencil, Trash2} from "lucide-react";
import Image from "next/image";

type Banner = {id: number; title_en: string; title_ar: string; image_url: string; link_type: string; is_active: boolean; sort_order: number};
type FormState = {title_en: string; title_ar: string; link_type: string; link_id: string; start_date: string; end_date: string; is_active: boolean};
const DEFAULT_FORM: FormState = {title_en: "", title_ar: "", link_type: "none", link_id: "", start_date: "", end_date: "", is_active: true};

export default function BannersPage() {
  const t = useTranslations("banners");
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = React.useState(false);
  const [editId, setEditId] = React.useState<number | null>(null);
  const [form, setForm] = React.useState<FormState>(DEFAULT_FORM);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data: banners, isLoading} = useQuery<Banner[]>({
    queryKey: ["banners"],
    queryFn: async () => {
      const res = await api.get<{data: Banner[]}>("/api/v1/admin/banners");
      return res.data.data ?? [];
    },
  });

  const save = useMutation({
    mutationFn: async (payload: object) => {
      if (editId) return api.put(`/api/v1/admin/banners/${editId}`, payload);
      return api.post("/api/v1/admin/banners", payload);
    },
    onSuccess: () => {qc.invalidateQueries({queryKey: ["banners"]}); toast.success("Saved"); setModalOpen(false);},
    onError: () => toast.error("Failed"),
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/banners/${id}`),
    onSuccess: () => {qc.invalidateQueries({queryKey: ["banners"]}); toast.success("Deleted"); setDeleteId(null);},
    onError: () => toast.error("Failed"),
  });

  const openAdd = () => {setEditId(null); setForm(DEFAULT_FORM); setModalOpen(true);};
  const openEdit = (b: Banner) => {setEditId(b.id); setForm({title_en: b.title_en, title_ar: b.title_ar, link_type: b.link_type, link_id: "", start_date: "", end_date: "", is_active: b.is_active}); setModalOpen(true);};

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t("title")}</h1>
        <Button onClick={openAdd} className="gap-2"><Plus className="h-4 w-4" />{t("addBanner")}</Button>
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({length: 3}).map((_, i) => <div key={i} className="h-40 bg-muted rounded animate-pulse" />)}
        </div>
      ) : (banners ?? []).length === 0 ? (
        <p className="text-muted-foreground text-center py-12">{t("noBanners")}</p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {(banners ?? []).map((banner) => (
            <div key={banner.id} className="relative rounded-lg overflow-hidden border group">
              <div className="relative h-32 bg-muted">
                {banner.image_url && <Image src={banner.image_url} alt={banner.title_en} fill className="object-cover" />}
              </div>
              <div className="p-3">
                <p className="font-medium text-sm truncate">{banner.title_en}</p>
                <p className="text-xs text-muted-foreground" dir="rtl">{banner.title_ar}</p>
              </div>
              <div className="absolute top-2 end-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <Button variant="secondary" size="icon" className="h-7 w-7" onClick={() => openEdit(banner)}><Pencil className="h-3 w-3" /></Button>
                <Button variant="destructive" size="icon" className="h-7 w-7" onClick={() => setDeleteId(banner.id)}><Trash2 className="h-3 w-3" /></Button>
              </div>
            </div>
          ))}
        </div>
      )}

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editId ? t("editBanner") : t("addBanner")}</DialogTitle></DialogHeader>
          <form onSubmit={(e) => {e.preventDefault(); save.mutate(form);}} className="space-y-3">
            <div>
              <Label>Title</Label>
              <BilingualInput valueEn={form.title_en} valueAr={form.title_ar} onChangeEn={(v) => setForm((f) => ({...f, title_en: v}))} onChangeAr={(v) => setForm((f) => ({...f, title_ar: v}))} />
            </div>
            <div><Label>{t("linkType")}</Label>
              <Select value={form.link_type} onValueChange={(v) => setForm((f): FormState => ({...f, link_type: v ?? "none"}))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">{t("none")}</SelectItem>
                  <SelectItem value="product">{t("product")}</SelectItem>
                  <SelectItem value="category">{t("category")}</SelectItem>
                  <SelectItem value="offer">{t("offer")}</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {form.link_type !== "none" && <div><Label>{t("linkId")}</Label><Input type="number" value={form.link_id} onChange={(e) => setForm((f) => ({...f, link_id: e.target.value}))} /></div>}
            <div className="grid grid-cols-2 gap-3">
              <div><Label>{t("startDate")}</Label><Input type="date" value={form.start_date} onChange={(e) => setForm((f) => ({...f, start_date: e.target.value}))} /></div>
              <div><Label>{t("endDate")}</Label><Input type="date" value={form.end_date} onChange={(e) => setForm((f) => ({...f, end_date: e.target.value}))} /></div>
            </div>
            <div className="flex items-center gap-2"><Switch checked={form.is_active} onCheckedChange={(v) => setForm((f) => ({...f, is_active: v}))} /><Label>{t("isActive")}</Label></div>
            <p className="text-xs text-muted-foreground">{t("recommendedSize")}</p>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={save.isPending}>Save</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)} title="Delete Banner" description="Are you sure?" onConfirm={() => deleteId && remove.mutate(deleteId)} />
    </div>
  );
}
