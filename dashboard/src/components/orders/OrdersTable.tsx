"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {Input} from "@/components/ui/input";
import {Button} from "@/components/ui/button";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {DataTable, type Column} from "@/components/common/DataTable";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {OrderStatusBadge} from "./OrderStatusBadge";
import {OrderDetailModal} from "./OrderDetailModal";
import {useOrders, type Order, type OrderStatus} from "@/hooks/useOrders";
import {formatDistanceToNow} from "date-fns";
import {useLocale} from "next-intl";
import {ar, enUS} from "date-fns/locale";
import {Download, Search} from "lucide-react";

const STATUSES: OrderStatus[] = ["pending", "confirmed", "preparing", "ready", "out_for_delivery", "delivered", "cancelled"];

export function OrdersTable() {
  const t = useTranslations("orders");
  const locale = useLocale();
  const dateLocale = locale === "ar" ? ar : enUS;

  const [search, setSearch] = React.useState("");
  const [status, setStatus] = React.useState<string>("all");
  const [page, setPage] = React.useState(1);
  const [selectedOrderId, setSelectedOrderId] = React.useState<number | null>(null);

  const {data, isLoading} = useOrders({
    page,
    search: search || undefined,
    status: status !== "all" ? status : undefined,
  });

  const columns: Column<Order>[] = [
    {
      key: "order_number",
      header: t("orderId"),
      cell: (row) => <span className="font-mono text-xs">#{row.order_number}</span>,
    },
    {
      key: "customer",
      header: t("customer"),
      cell: (row) => row.customer_name,
    },
    {
      key: "items",
      header: t("items"),
      cell: (row) => row.items.length,
      className: "hidden md:table-cell",
    },
    {
      key: "total",
      header: t("total"),
      cell: (row) => <MoneyDisplay piastres={row.total} />,
    },
    {
      key: "status",
      header: t("status"),
      cell: (row) => <OrderStatusBadge status={row.status} />,
    },
    {
      key: "time",
      header: t("time"),
      cell: (row) => (
        <span className="text-xs text-muted-foreground">
          {formatDistanceToNow(new Date(row.created_at), {addSuffix: true, locale: dateLocale})}
        </span>
      ),
      className: "hidden sm:table-cell",
    },
    {
      key: "actions",
      header: "",
      cell: (row) => (
        <Button variant="ghost" size="sm" onClick={() => setSelectedOrderId(row.id)}>
          View
        </Button>
      ),
    },
  ];

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search className="absolute start-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            className="ps-9"
            placeholder={t("searchPlaceholder")}
            value={search}
            onChange={(e) => {setSearch(e.target.value); setPage(1);}}
          />
        </div>
        <Select value={status} onValueChange={(v) => {setStatus(v ?? ""); setPage(1);}}>
          <SelectTrigger className="w-44">
            <SelectValue placeholder={t("filterStatus")} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            {STATUSES.map((s) => (
              <SelectItem key={s} value={s}>{s.replace(/_/g, " ")}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button variant="outline" size="sm" className="gap-2">
          <Download className="h-4 w-4" />
          {t("exportCsv")}
        </Button>
      </div>

      <DataTable
        columns={columns}
        data={data?.data ?? []}
        isLoading={isLoading}
        emptyMessage={t("noOrders")}
        page={page}
        totalPages={data?.meta.last_page ?? 1}
        onPageChange={setPage}
        rowKey={(row) => row.id}
      />

      <OrderDetailModal orderId={selectedOrderId} onClose={() => setSelectedOrderId(null)} />
    </div>
  );
}
