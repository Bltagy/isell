"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Switch} from "@/components/ui/switch";
import {DataTable, type Column} from "@/components/common/DataTable";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter} from "@/components/ui/dialog";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {BilingualInput} from "@/components/common/BilingualInput";
import {toast} from "sonner";
import {Plus, Pencil, Trash2} from "lucide-react";
import Image from "next/image";

type Category = {
  id: number;
  name_en: string;
  name_ar: string;
  image_url?: string;
  parent_id?: number;
  parent_name?: string;
  products_count: number;
  is_active: boolean;
  sort_order: number;
};

type FormState = {
  name_en: string;
  name_ar: string;
  parent_id: string;
  sort_order: string;
  is_active: boolean;
};

const DEFAULT_FORM: FormState = {name_en: "", name_ar: "", parent_id: "", sort_order: "0", is_active: true};

export default function CategoriesPage() {
  const t = useTranslations("menu");
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = React.useState(false);
  const [editId, setEditId] = React.useState<number | null>(null);
  const [form, setForm] = React.useState<FormState>(DEFAULT_FORM);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data: categories, isLoading} = useQuery<Category[]>({
    queryKey: ["categories"],
    queryFn: async () => {
      const res = await api.get<{data: Category[]}>("/api/v1/admin/categories");
      return res.data.data ?? [];
    },
  });

  const save = useMutation({
    mutationFn: async (payload: object) => {
      if (editId) return api.put(`/api/v1/admin/categories/${editId}`, payload);
      return api.post("/api/v1/admin/categories", payload);
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["categories"]});
      toast.success("Saved");
      setModalOpen(false);
    },
    onError: () => toast.error("Failed to save"),
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/categories/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["categories"]});
      toast.success("Deleted");
      setDeleteId(null);
    },
    onError: () => toast.error("Failed to delete"),
  });

  const toggleActive = useMutation({
    mutationFn: ({id, is_active}: {id: number; is_active: boolean}) =>
      api.put(`/api/v1/admin/categories/${id}`, {is_active}),
    onSuccess: () => qc.invalidateQueries({queryKey: ["categories"]}),
  });

  const openAdd = () => { setEditId(null); setForm(DEFAULT_FORM); setModalOpen(true); };
  const openEdit = (cat: Category) => {
    setEditId(cat.id);
    setForm({name_en: cat.name_en, name_ar: cat.name_ar, parent_id: cat.parent_id?.toString() ?? "", sort_order: cat.sort_order.toString(), is_active: cat.is_active});
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    save.mutate({...form, sort_order: Number(form.sort_order), parent_id: form.parent_id || null});
  };

  const columns: Column<Category>[] = [
    {key: "image", header: "", cell: (row) => row.image_url ? <div className="relative h-8 w-8 rounded overflow-hidden"><Image src={row.image_url} alt={row.name_en} fill className="object-cover" /></div> : <div className="h-8 w-8 rounded bg-muted" />},
    {key: "name", header: "Name", cell: (row) => <div><p className="font-medium">{row.name_en}</p><p className="text-xs text-muted-foreground" dir="rtl">{row.name_ar}</p></div>},
    {key: "parent", header: "Parent", cell: (row) => row.parent_name ?? "—", className: "hidden md:table-cell"},
    {key: "products", header: t("productsCount"), cell: (row) => row.products_count, className: "hidden sm:table-cell"},
    {key: "active", header: t("isActive"), cell: (row) => <Switch checked={row.is_active} onCheckedChange={(v) => toggleActive.mutate({id: row.id, is_active: v})} />},
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
        <h1 className="text-2xl font-bold">{t("categoriesTitle")}</h1>
        <Button onClick={openAdd} className="gap-2"><Plus className="h-4 w-4" />{t("addCategory")}</Button>
      </div>

      <DataTable columns={columns} data={categories ?? []} isLoading={isLoading} emptyMessage={t("noCategories")} rowKey={(row) => row.id} />

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editId ? t("editCategory") : t("addCategory")}</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label>Name</Label>
              <BilingualInput
                valueEn={form.name_en}
                valueAr={form.name_ar}
                onChangeEn={(v) => setForm((f) => ({...f, name_en: v}))}
                onChangeAr={(v) => setForm((f) => ({...f, name_ar: v}))}
              />
            </div>
            <div>
              <Label>{t("parentCategory")}</Label>
              <Select value={form.parent_id} onValueChange={(v) => setForm((f) => ({...f, parent_id: v ?? ""}))}>
                <SelectTrigger><SelectValue placeholder="None" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="">None</SelectItem>
                  {(categories ?? []).filter((c) => c.id !== editId).map((c) => (
                    <SelectItem key={c.id} value={c.id.toString()}>{c.name_en}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>{t("sortOrder")}</Label>
              <Input type="number" value={form.sort_order} onChange={(e) => setForm((f) => ({...f, sort_order: e.target.value}))} />
            </div>
            <div className="flex items-center gap-2">
              <Switch checked={form.is_active} onCheckedChange={(v) => setForm((f) => ({...f, is_active: v}))} />
              <Label>{t("isActive")}</Label>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={save.isPending}>Save</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={(o) => !o && setDeleteId(null)}
        title="Delete Category"
        description="Are you sure? This cannot be undone."
        onConfirm={() => deleteId && remove.mutate(deleteId)}
      />
    </div>
  );
}
