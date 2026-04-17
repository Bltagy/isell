"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useParams, useRouter} from "next/navigation";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {Avatar, AvatarFallback} from "@/components/ui/avatar";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {DataTable, type Column} from "@/components/common/DataTable";
import {OrderStatusBadge} from "@/components/orders/OrderStatusBadge";
import {ArrowLeft} from "lucide-react";
import {format} from "date-fns";
import type {OrderStatus} from "@/hooks/useOrders";

type CustomerDetail = {
  id: number; name: string; email: string; phone: string;
  is_active: boolean; loyalty_points: number; joined_at: string;
  total_orders: number; total_spent: number; avg_order_value: number;
  orders: {id: number; order_number: string; total: number; status: OrderStatus; created_at: string}[];
  addresses: {id: number; label: string; address: string}[];
};

export default function CustomerDetailPage() {
  const t = useTranslations("customers");
  const router = useRouter();
  const {id} = useParams();

  const {data, isLoading} = useQuery<CustomerDetail>({
    queryKey: ["customer", id],
    queryFn: async () => {
      const res = await api.get<{data: CustomerDetail}>(`/api/v1/admin/customers/${id}`);
      const d = res.data.data as Record<string, unknown>;
      // Normalize field names
      return {
        ...d,
        joined_at: d.joined_at ?? d.created_at,
        total_orders: d.total_orders ?? d.orders_count ?? 0,
        total_spent: d.total_spent ?? 0,
        avg_order_value: d.avg_order_value ?? 0,
        loyalty_points: (d.profile as Record<string, unknown>)?.loyalty_points ?? 0,
        orders: (d.orders as unknown[]) ?? [],
        addresses: (d.addresses as unknown[]) ?? [],
      } as CustomerDetail;
    },
  });

  const orderColumns: Column<CustomerDetail["orders"][0]>[] = [
    {key: "num", header: "Order #", cell: (row) => <span className="font-mono text-xs">#{row.order_number}</span>},
    {key: "total", header: "Total", cell: (row) => <MoneyDisplay piastres={row.total} />},
    {key: "status", header: "Status", cell: (row) => <OrderStatusBadge status={row.status} />},
    {key: "date", header: "Date", cell: (row) => format(new Date(row.created_at), "dd/MM/yyyy")},
  ];

  if (isLoading) return <div className="animate-pulse space-y-4"><div className="h-32 bg-muted rounded" /><div className="h-64 bg-muted rounded" /></div>;
  if (!data) return null;

  return (
    <div className="space-y-4 max-w-3xl">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => router.back()}><ArrowLeft className="h-4 w-4 rtl:rotate-180" /></Button>
        <h1 className="text-2xl font-bold">{data.name}</h1>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t("totalOrders")}</CardTitle></CardHeader><CardContent><p className="text-2xl font-bold">{data.total_orders}</p></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t("totalSpent")}</CardTitle></CardHeader><CardContent><MoneyDisplay piastres={data.total_spent} className="text-2xl font-bold" /></CardContent></Card>
        <Card><CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t("loyaltyPoints")}</CardTitle></CardHeader><CardContent><p className="text-2xl font-bold">{data.loyalty_points}</p></CardContent></Card>
      </div>

      <Card>
        <CardContent className="pt-4 flex items-center gap-4">
          <Avatar className="h-12 w-12"><AvatarFallback>{data.name.slice(0, 2).toUpperCase()}</AvatarFallback></Avatar>
          <div>
            <p className="font-semibold">{data.name}</p>
            <p className="text-sm text-muted-foreground">{data.email}</p>
            <p className="text-sm text-muted-foreground">{data.phone}</p>
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="orders">
        <TabsList>
          <TabsTrigger value="orders">{t("orderHistory")}</TabsTrigger>
          <TabsTrigger value="addresses">{t("addresses")}</TabsTrigger>
        </TabsList>
        <TabsContent value="orders" className="mt-4">
          <DataTable columns={orderColumns} data={data.orders} emptyMessage="No orders" rowKey={(row) => row.id} />
        </TabsContent>
        <TabsContent value="addresses" className="mt-4 space-y-2">
          {data.addresses.map((addr) => (
            <Card key={addr.id}><CardContent className="pt-3 pb-3"><p className="font-medium text-sm">{addr.label}</p><p className="text-sm text-muted-foreground">{addr.address}</p></CardContent></Card>
          ))}
        </TabsContent>
      </Tabs>
    </div>
  );
}
