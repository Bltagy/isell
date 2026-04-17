"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Skeleton} from "@/components/ui/skeleton";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {DataTable, type Column} from "@/components/common/DataTable";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer
} from "recharts";
import {Download, TrendingUp} from "lucide-react";

type Period = "today" | "7d" | "30d" | "3m";

type AnalyticsData = {
  total_revenue: number;
  total_orders: number;
  avg_order_value: number;
  new_customers: number;
  returning_rate: number;
  revenue_over_time: {date: string; revenue: number}[];
  orders_by_status: {status: string; count: number}[];
  orders_by_payment: {method: string; count: number}[];
  top_products: {name: string; orders: number; revenue: number}[];
  top_customers: {name: string; orders: number; spent: number}[];
};

const COLORS = ["#FF6B35", "#6366f1", "#f59e0b", "#10b981", "#ef4444", "#8b5cf6"];

export default function AnalyticsPage() {
  const t = useTranslations("analytics");
  const [period, setPeriod] = React.useState<Period>("30d");

  const {data, isLoading} = useQuery<AnalyticsData>({
    queryKey: ["analytics", period],
    queryFn: async () => {
      const res = await api.get<{data: Record<string, unknown>}>("/api/v1/admin/dashboard");
      const d = res.data.data;
      return {
        total_revenue: (d.today_revenue as number) ?? 0,
        total_orders: (d.today_orders as number) ?? 0,
        avg_order_value: (d.today_orders as number) ? Math.round(((d.today_revenue as number) ?? 0) / (d.today_orders as number)) : 0,
        new_customers: (d.total_customers as number) ?? 0,
        returning_rate: 0,
        revenue_over_time: ((d.orders_chart as {date: string; revenue: number}[]) ?? []).map((c) => ({date: c.date, revenue: c.revenue})),
        orders_by_status: [],
        orders_by_payment: [],
        top_products: ((d.top_products as {product_name_snapshot: string; total_sold: number}[]) ?? []).map((p) => ({name: p.product_name_snapshot, orders: p.total_sold, revenue: 0})),
        top_customers: [],
      } as AnalyticsData;
    },
  });

  const PERIODS: {key: Period; label: string}[] = [
    {key: "today", label: t("today")},
    {key: "7d", label: t("last7Days")},
    {key: "30d", label: t("last30Days")},
    {key: "3m", label: t("last3Months")},
  ];

  const topProductColumns: Column<{name: string; orders: number; revenue: number}>[] = [
    {key: "name", header: "Product", cell: (row) => row.name},
    {key: "orders", header: "Orders", cell: (row) => row.orders},
    {key: "revenue", header: "Revenue", cell: (row) => <MoneyDisplay piastres={row.revenue} />},
  ];

  const topCustomerColumns: Column<{name: string; orders: number; spent: number}>[] = [
    {key: "name", header: "Customer", cell: (row) => row.name},
    {key: "orders", header: "Orders", cell: (row) => row.orders},
    {key: "spent", header: "Spent", cell: (row) => <MoneyDisplay piastres={row.spent} />},
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <h1 className="text-2xl font-bold">{t("title")}</h1>
        <div className="flex items-center gap-2">
          <div className="flex gap-1">
            {PERIODS.map((p) => (
              <Button key={p.key} variant={period === p.key ? "default" : "outline"} size="sm" onClick={() => setPeriod(p.key)}>
                {p.label}
              </Button>
            ))}
          </div>
          <Button variant="outline" size="sm" className="gap-2">
            <Download className="h-4 w-4" />{t("exportCsv")}
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        {isLoading ? Array.from({length: 5}).map((_, i) => <Skeleton key={i} className="h-24" />) : (
          <>
            {[
              {label: t("totalRevenue"), value: <MoneyDisplay piastres={data?.total_revenue ?? 0} />, icon: "💰"},
              {label: t("totalOrders"), value: data?.total_orders ?? 0, icon: "📦"},
              {label: t("avgOrderValue"), value: <MoneyDisplay piastres={data?.avg_order_value ?? 0} />, icon: "📊"},
              {label: t("newCustomers"), value: data?.new_customers ?? 0, icon: "👥"},
              {label: t("returningRate"), value: `${(data?.returning_rate ?? 0).toFixed(1)}%`, icon: "🔄"},
            ].map((kpi) => (
              <Card key={kpi.label}>
                <CardContent className="pt-4">
                  <p className="text-2xl">{kpi.icon}</p>
                  <p className="text-xl font-bold mt-1">{kpi.value}</p>
                  <p className="text-xs text-muted-foreground">{kpi.label}</p>
                </CardContent>
              </Card>
            ))}
          </>
        )}
      </div>

      {/* Charts row */}
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader><CardTitle className="text-base">{t("revenueOverTime")}</CardTitle></CardHeader>
          <CardContent>
            {isLoading ? <Skeleton className="h-48" /> : (
              <ResponsiveContainer width="100%" height={200}>
                <AreaChart data={data?.revenue_over_time ?? []}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                  <XAxis dataKey="date" tick={{fontSize: 10}} />
                  <YAxis tick={{fontSize: 10}} />
                  <Tooltip />
                  <Area type="monotone" dataKey="revenue" stroke="#FF6B35" fill="#FF6B3520" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">{t("ordersByStatus")}</CardTitle></CardHeader>
          <CardContent>
            {isLoading ? <Skeleton className="h-48" /> : (
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie data={data?.orders_by_status ?? []} dataKey="count" nameKey="status" cx="50%" cy="50%" outerRadius={70}>
                    {(data?.orders_by_status ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Tables */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle className="text-base">{t("topProducts")}</CardTitle></CardHeader>
          <CardContent>
            <DataTable columns={topProductColumns} data={data?.top_products ?? []} isLoading={isLoading} emptyMessage={t("noData")} rowKey={(row) => row.name} />
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle className="text-base">{t("topCustomers")}</CardTitle></CardHeader>
          <CardContent>
            <DataTable columns={topCustomerColumns} data={data?.top_customers ?? []} isLoading={isLoading} emptyMessage={t("noData")} rowKey={(row) => row.name} />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
