"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {DataTable, type Column} from "@/components/common/DataTable";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter} from "@/components/ui/dialog";
import {Avatar, AvatarFallback} from "@/components/ui/avatar";
import {toast} from "sonner";
import {Plus, Pencil, Trash2} from "lucide-react";

type Driver = {id: number; name: string; email: string; phone: string; active_orders_count: number; total_deliveries: number; is_active: boolean};
type FormState = {name: string; email: string; phone: string; password: string; is_active: boolean};
const DEFAULT_FORM: FormState = {name: "", email: "", phone: "", password: "", is_active: true};

export default function DriversPage() {
  const t = useTranslations("drivers");
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = React.useState(false);
  const [editId, setEditId] = React.useState<number | null>(null);
  const [form, setForm] = React.useState<FormState>(DEFAULT_FORM);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data: drivers, isLoading} = useQuery<Driver[]>({
    queryKey: ["drivers"],
    queryFn: async () => {
      const res = await api.get<{data: Driver[]}>("/api/v1/admin/drivers");
      return res.data.data ?? [];
    },
  });

  const save = useMutation({
    mutationFn: async (payload: FormState) => {
      if (editId) return api.put(`/api/v1/admin/drivers/${editId}`, payload);
      return api.post("/api/v1/admin/drivers", payload);
    },
    onSuccess: () => {qc.invalidateQueries({queryKey: ["drivers"]}); toast.success("Saved"); setModalOpen(false);},
    onError: () => toast.error("Failed"),
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/drivers/${id}`),
    onSuccess: () => {qc.invalidateQueries({queryKey: ["drivers"]}); toast.success("Deleted"); setDeleteId(null);},
    onError: () => toast.error("Failed"),
  });

  const toggleActive = useMutation({
    mutationFn: ({id, is_active}: {id: number; is_active: boolean}) =>
      api.put(`/api/v1/admin/drivers/${id}`, {is_active}),
    onSuccess: () => qc.invalidateQueries({queryKey: ["drivers"]}),
    onError: () => toast.error("Failed"),
  });

  const openAdd = () => {setEditId(null); setForm(DEFAULT_FORM); setModalOpen(true);};
  const openEdit = (d: Driver) => {setEditId(d.id); setForm({name: d.name, email: d.email, phone: d.phone, password: "", is_active: d.is_active}); setModalOpen(true);};

  const columns: Column<Driver>[] = [
    {key: "avatar", header: "", cell: (row) => <Avatar className="h-8 w-8"><AvatarFallback className="text-xs">{row.name.slice(0, 2).toUpperCase()}</AvatarFallback></Avatar>},
    {key: "name", header: t("name"), cell: (row) => <div><p className="font-medium">{row.name}</p><p className="text-xs text-muted-foreground">{row.phone}</p></div>},
    {key: "active_orders", header: t("activeOrders"), cell: (row) => row.active_orders_count},
    {key: "deliveries", header: t("totalDeliveries"), cell: (row) => row.total_deliveries, className: "hidden sm:table-cell"},
    {key: "status", header: "Active", cell: (row) => <Switch checked={row.is_active} onCheckedChange={(v) => toggleActive.mutate({id: row.id, is_active: v})} />},
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
        <Button onClick={openAdd} className="gap-2"><Plus className="h-4 w-4" />{t("addDriver")}</Button>
      </div>
      <DataTable columns={columns} data={drivers ?? []} isLoading={isLoading} emptyMessage={t("noDrivers")} rowKey={(row) => row.id} />

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editId ? t("editDriver") : t("addDriver")}</DialogTitle></DialogHeader>
          <form onSubmit={(e) => {e.preventDefault(); save.mutate(form);}} className="space-y-3">
            <div><Label>{t("name")}</Label><Input value={form.name} onChange={(e) => setForm((f) => ({...f, name: e.target.value}))} required /></div>
            <div><Label>{t("email")}</Label><Input type="email" value={form.email} onChange={(e) => setForm((f) => ({...f, email: e.target.value}))} required /></div>
            <div><Label>{t("phone")}</Label><Input value={form.phone} onChange={(e) => setForm((f) => ({...f, phone: e.target.value}))} required /></div>
            <div><Label>{t("password")}{editId ? " (leave blank to keep)" : ""}</Label><Input type="password" value={form.password} onChange={(e) => setForm((f) => ({...f, password: e.target.value}))} required={!editId} /></div>
            <div className="flex items-center gap-2"><Switch checked={form.is_active} onCheckedChange={(v) => setForm((f) => ({...f, is_active: v}))} /><Label>{t("isActive")}</Label></div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={save.isPending}>Save</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)} title="Delete Driver" description="Are you sure?" onConfirm={() => deleteId && remove.mutate(deleteId)} />
    </div>
  );
}
