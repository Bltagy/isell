"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {useRouter} from "next/navigation";
import {useLocale} from "next-intl";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Switch} from "@/components/ui/switch";
import {Input} from "@/components/ui/input";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {DataTable, type Column} from "@/components/common/DataTable";
import {ConfirmDialog} from "@/components/common/ConfirmDialog";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {toast} from "sonner";
import {Plus, Pencil, Trash2, Search} from "lucide-react";
import Image from "next/image";

type Product = {
  id: number;
  name_en: string;
  name_ar: string;
  price: number;
  category_name: string;
  category_id: number;
  image_url?: string;
  is_available: boolean;
  is_featured: boolean;
};

type Category = {id: number; name_en: string};

export default function ProductsPage() {
  const t = useTranslations("menu");
  const locale = useLocale();
  const router = useRouter();
  const qc = useQueryClient();

  const [search, setSearch] = React.useState("");
  const [categoryFilter, setCategoryFilter] = React.useState("all");
  const [page, setPage] = React.useState(1);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);

  const {data: categories} = useQuery<Category[]>({
    queryKey: ["categories"],
    queryFn: async () => {
      const res = await api.get<{data: Category[]}>("/api/v1/admin/categories");
      return res.data.data ?? [];
    },
  });

  const {data, isLoading} = useQuery<{data: Product[]; meta: {last_page: number}}>({
    queryKey: ["products", page, search, categoryFilter],
    queryFn: async () => {
      const res = await api.get("/api/v1/admin/products", {
        params: {page, search: search || undefined, category_id: categoryFilter !== "all" ? categoryFilter : undefined},
      });
      return res.data;
    },
  });

  const toggleAvailable = useMutation({
    mutationFn: ({id, is_available}: {id: number; is_available: boolean}) =>
      api.put(`/api/v1/admin/products/${id}`, {is_available}),
    onSuccess: () => qc.invalidateQueries({queryKey: ["products"]}),
  });

  const remove = useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/admin/products/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["products"]});
      toast.success("Deleted");
      setDeleteId(null);
    },
    onError: () => toast.error("Failed"),
  });

  const columns: Column<Product>[] = [
    {key: "image", header: "", cell: (row) => row.image_url ? <div className="relative h-10 w-10 rounded overflow-hidden"><Image src={row.image_url} alt={row.name_en} fill className="object-cover" /></div> : <div className="h-10 w-10 rounded bg-muted" />},
    {key: "name", header: "Name", cell: (row) => <div><p className="font-medium">{row.name_en}</p><p className="text-xs text-muted-foreground" dir="rtl">{row.name_ar}</p></div>},
    {key: "price", header: "Price", cell: (row) => <MoneyDisplay piastres={row.price} />},
    {key: "category", header: "Category", cell: (row) => row.category_name, className: "hidden md:table-cell"},
    {key: "available", header: t("isAvailable"), cell: (row) => <Switch checked={row.is_available} onCheckedChange={(v) => toggleAvailable.mutate({id: row.id, is_available: v})} />},
    {key: "actions", header: "", cell: (row) => (
      <div className="flex gap-1">
        <Button variant="ghost" size="icon" onClick={() => router.push(`/${locale}/menu/products/${row.id}`)}><Pencil className="h-4 w-4" /></Button>
        <Button variant="ghost" size="icon" onClick={() => setDeleteId(row.id)} className="text-destructive hover:text-destructive"><Trash2 className="h-4 w-4" /></Button>
      </div>
    )},
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{t("productsTitle")}</h1>
        <Button onClick={() => router.push(`/${locale}/menu/products/new`)} className="gap-2">
          <Plus className="h-4 w-4" />{t("addProduct")}
        </Button>
      </div>

      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search className="absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input className="ps-9" placeholder="Search products..." value={search} onChange={(e) => {setSearch(e.target.value); setPage(1);}} />
        </div>
        <Select value={categoryFilter} onValueChange={(v) => {setCategoryFilter(v ?? "all"); setPage(1);}}>
          <SelectTrigger className="w-44"><SelectValue placeholder="All Categories" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            {(categories ?? []).map((c) => <SelectItem key={c.id} value={c.id.toString()}>{c.name_en}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      <DataTable columns={columns} data={data?.data ?? []} isLoading={isLoading} emptyMessage={t("noProducts")} page={page} totalPages={data?.meta.last_page ?? 1} onPageChange={setPage} rowKey={(row) => row.id} />

      <ConfirmDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)} title="Delete Product" description="Are you sure?" onConfirm={() => deleteId && remove.mutate(deleteId)} />
    </div>
  );
}
