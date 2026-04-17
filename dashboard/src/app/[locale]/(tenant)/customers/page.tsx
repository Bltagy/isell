"use client";

import React from "react";
import {useTranslations, useLocale} from "next-intl";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {useRouter} from "next/navigation";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {DataTable, type Column} from "@/components/common/DataTable";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {Avatar, AvatarFallback} from "@/components/ui/avatar";
import {Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter} from "@/components/ui/dialog";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {Search, Filter, Pencil, Trash2, Eye} from "lucide-react";
import {format} from "date-fns";
import {toast} from "sonner";

type Customer = {
  id: number;
  name: string;
  email: string;
  phone: string;
  orders_count: number;
  total_spent: number;
  joined_at?: string;
  created_at?: string;
  is_active: boolean;
};

export default function CustomersPage() {
  const t = useTranslations("customers");
  const locale = useLocale();
  const router = useRouter();
  const qc = useQueryClient();

  const [search, setSearch] = React.useState("");
  const [page, setPage] = React.useState(1);
  const [statusFilter, setStatusFilter] = React.useState<string>("all");
  const [editCustomer, setEditCustomer] = React.useState<Customer | null>(null);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data, isLoading} = useQuery<{data: Customer[]; meta: {last_page: number}}>({
    queryKey: ["customers", page, search, statusFilter],
    queryFn: async () => {
      const res = await api.get("/api/v1/admin/customers", {
        params: {
          page,
          search: search || undefined,
          status: statusFilter !== "all" ? statusFilter : undefined,
        },
      });
      return res.data;
    },
  });

  const toggle = useMutation({
    mutationFn: (id: number) => api.put(`/api/v1/admin/customers/${id}/toggle-status`),
    onSuccess: () => qc.invalidateQueries({queryKey: ["customers"]}),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/customers/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["customers"]});
      toast.success("Customer deleted");
      setDeleteId(null);
    },
    onError: () => toast.error("Failed to delete"),
  });

  const columns: Column<Customer>[] = [
    {
      key: "avatar", header: "",
      cell: (row) => <Avatar className="h-8 w-8"><AvatarFallback className="text-xs">{row.name.slice(0, 2).toUpperCase()}</AvatarFallback></Avatar>,
    },
    {
      key: "name", header: t("name"),
      cell: (row) => (
        <div>
          <p className="font-medium">{row.name}</p>
          <p className="text-xs text-muted-foreground">{row.email}</p>
        </div>
      ),
    },
    {key: "phone", header: t("phone"), cell: (row) => row.phone || "—", className: "hidden md:table-cell"},
    {key: "orders", header: t("totalOrders"), cell: (row) => row.orders_count},
    {key: "spent", header: t("totalSpent"), cell: (row) => <MoneyDisplay piastres={row.total_spent} />},
    {
      key: "joined", header: t("joinedDate"),
      cell: (row) => { try { return format(new Date(row.joined_at ?? row.created_at ?? ""), "dd/MM/yyyy"); } catch { return "—"; } },
      className: "hidden sm:table-cell",
    },
    {
      key: "status", header: t("status"),
      cell: (row) => <Switch checked={row.is_active} onCheckedChange={() => toggle.mutate(row.id)} />,
    },
    {
      key: "actions", header: "",
      cell: (row) => (
        <div className="flex gap-1">
          <Button variant="ghost" size="icon" onClick={() => router.push(`/${locale}/customers/${row.id}`)} title="View">
            <Eye className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon" onClick={() => setEditCustomer(row)} title="Edit">
            <Pencil className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive" onClick={() => setDeleteId(row.id)} title="Delete">
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">{t("title")}</h1>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            className="ps-9"
            placeholder={t("searchPlaceholder")}
            value={search}
            onChange={(e) => {setSearch(e.target.value); setPage(1);}}
          />
        </div>
        <Select value={statusFilter} onValueChange={(v) => {setStatusFilter(v ?? "all"); setPage(1);}}>
          <SelectTrigger className="w-40">
            <Filter className="h-4 w-4 me-2 text-muted-foreground" />
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t("allStatuses")}</SelectItem>
            <SelectItem value="active">{t("active")}</SelectItem>
            <SelectItem value="inactive">{t("inactive")}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={data?.data ?? []}
        isLoading={isLoading}
        emptyMessage={t("noCustomers")}
        page={page}
        totalPages={data?.meta.last_page ?? 1}
        onPageChange={setPage}
        rowKey={(row) => row.id}
      />

      {/* Edit Modal */}
      {editCustomer && (
        <EditCustomerModal
          customer={editCustomer}
          onClose={() => setEditCustomer(null)}
          onSaved={() => {
            qc.invalidateQueries({queryKey: ["customers"]});
            setEditCustomer(null);
          }}
        />
      )}

      {/* Delete Confirm */}
      <ConfirmDialog
        open={deleteId !== null}
        onOpenChange={(open) => { if (!open) setDeleteId(null); }}
        title={t("deleteCustomer")}
        description={t("deleteCustomerConfirm")}
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        variant="destructive"
      />
    </div>
  );
}

// ── Edit Customer Modal ────────────────────────────────────────────────────────

function EditCustomerModal({customer, onClose, onSaved}: {customer: Customer; onClose: () => void; onSaved: () => void}) {
  const t = useTranslations("customers");
  const [form, setForm] = React.useState({
    name: customer.name,
    email: customer.email ?? "",
    phone: customer.phone ?? "",
    password: "",
    is_active: customer.is_active,
  });

  const update = useMutation({
    mutationFn: () => api.put(`/api/v1/admin/customers/${customer.id}`, {
      name: form.name,
      email: form.email || undefined,
      phone: form.phone || undefined,
      password: form.password || undefined,
      is_active: form.is_active,
    }),
    onSuccess: () => {
      toast.success(t("customerUpdated"));
      onSaved();
    },
    onError: () => toast.error("Failed to update"),
  });

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{t("editCustomer")}</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 py-2">
          <div>
            <Label>{t("name")}</Label>
            <Input value={form.name} onChange={(e) => setForm((f) => ({...f, name: e.target.value}))} />
          </div>
          <div>
            <Label>{t("email")}</Label>
            <Input type="email" value={form.email} onChange={(e) => setForm((f) => ({...f, email: e.target.value}))} />
          </div>
          <div>
            <Label>{t("phone")}</Label>
            <Input value={form.phone} onChange={(e) => setForm((f) => ({...f, phone: e.target.value}))} />
          </div>
          <div>
            <Label>{t("newPassword")}</Label>
            <Input
              type="password"
              placeholder={t("leaveBlankToKeep")}
              value={form.password}
              onChange={(e) => setForm((f) => ({...f, password: e.target.value}))}
            />
          </div>
          <div className="flex items-center gap-2">
            <Switch checked={form.is_active} onCheckedChange={(v) => setForm((f) => ({...f, is_active: v}))} />
            <Label>{t("active")}</Label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={() => update.mutate()} disabled={update.isPending}>
            {update.isPending ? "Saving..." : t("save")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
