"use client";

import React from "react";
import {useQuery} from "@tanstack/react-query";
import {useTranslations, useLocale} from "next-intl";
import {ShoppingBag, DollarSign, Clock, Users, TrendingUp, TrendingDown} from "lucide-react";
import {Card, CardContent, CardHeader, CardTitle} from "@/components/ui/card";
import {Badge} from "@/components/ui/badge";
import {Button} from "@/components/ui/button";
import {Skeleton} from "@/components/ui/skeleton";
import {api} from "@/lib/api";
import {RevenueChart} from "@/components/charts/RevenueChart";
import {TopProductsChart} from "@/components/charts/TopProductsChart";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {useRealtime} from "@/hooks/useRealtime";
import {useAuthStore} from "@/stores/authStore";
import {cn} from "@/lib/utils";
import {formatDistanceToNow} from "date-fns";
import {ar, enUS} from "date-fns/locale";

type DashboardStats = {
  today_orders: number;
  today_orders_change: number;
  today_revenue: number;
  today_revenue_change: number;
  pending_orders: number;
  total_customers: number;
  recent_orders: {
    id: number;
    order_number: string;
    customer_name: string;
    items_count: number;
    total: number;
    status: string;
    created_at: string;
  }[];
};

const STATUS_COLORS: Record<string, string> = {
  pending: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
  confirmed: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
  preparing: "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400",
  out_for_delivery: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400",
  delivered: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
  cancelled: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
  ready: "bg-teal-100 text-teal-800 dark:bg-teal-900/30 dark:text-teal-400",
};

function StatCard({
  title,
  value,
  change,
  icon: Icon,
  isMoney,
  warning,
}: {
  title: string;
  value: number;
  change?: number;
  icon: React.ElementType;
  isMoney?: boolean;
  warning?: boolean;
}) {
  const [displayed, setDisplayed] = React.useState(0);

  React.useEffect(() => {
    let start = 0;
    const end = value;
    if (start === end) return;
    const duration = 800;
    const step = Math.ceil(end / (duration / 16));
    const timer = setInterval(() => {
      start = Math.min(start + step, end);
      setDisplayed(start);
      if (start >= end) clearInterval(timer);
    }, 16);
    return () => clearInterval(timer);
  }, [value]);

  return (
    <Card className={cn(warning && "border-orange-400")}>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon className={cn("h-4 w-4", warning ? "text-orange-500" : "text-muted-foreground")} />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">
          {isMoney ? <MoneyDisplay piastres={displayed} /> : displayed.toLocaleString()}
        </div>
        {change !== undefined && (
          <p className={cn("text-xs mt-1 flex items-center gap-1", change >= 0 ? "text-green-600" : "text-red-500")}>
            {change >= 0 ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
            {Math.abs(change).toFixed(1)}% vs yesterday
          </p>
        )}
      </CardContent>
    </Card>
  );
}

export default function DashboardPage() {
  const t = useTranslations("dashboard");
  const locale = useLocale();
  const {user} = useAuthStore();

  useRealtime(user?.id);

  const {data: stats, isLoading} = useQuery<DashboardStats>({
    queryKey: ["dashboard-stats"],
    queryFn: async () => {
      const res = await api.get<{data: DashboardStats}>("/api/v1/admin/dashboard");
      return res.data.data;
    },
    refetchInterval: 60_000,
  });

  const dateLocale = locale === "ar" ? ar : enUS;

  return (
    <div className="space-y-6">
      {/* Stats row */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {isLoading ? (
          Array.from({length: 4}).map((_, i) => <Skeleton key={i} className="h-28" />)
        ) : (
          <>
            <StatCard
              title={t("todayOrders")}
              value={stats?.today_orders ?? 0}
              change={stats?.today_orders_change}
              icon={ShoppingBag}
            />
            <StatCard
              title={t("todayRevenue")}
              value={stats?.today_revenue ?? 0}
              change={stats?.today_revenue_change}
              icon={DollarSign}
              isMoney
            />
            <StatCard
              title={t("pendingOrders")}
              value={stats?.pending_orders ?? 0}
              icon={Clock}
              warning={(stats?.pending_orders ?? 0) > 10}
            />
            <StatCard
              title={t("totalCustomers")}
              value={stats?.total_customers ?? 0}
              icon={Users}
            />
          </>
        )}
      </div>

      {/* Charts row */}
      <div className="grid gap-4 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle className="text-base">{t("revenueChart")}</CardTitle>
          </CardHeader>
          <CardContent>
            <RevenueChart />
          </CardContent>
        </Card>
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">{t("topProducts")}</CardTitle>
          </CardHeader>
          <CardContent>
            <TopProductsChart />
          </CardContent>
        </Card>
      </div>

      {/* Recent orders */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("recentOrders")}</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              {Array.from({length: 5}).map((_, i) => (
                <Skeleton key={i} className="h-12" />
              ))}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-muted-foreground">
                    <th className="pb-2 text-start font-medium">{t("orderId")}</th>
                    <th className="pb-2 text-start font-medium">{t("customer")}</th>
                    <th className="pb-2 text-start font-medium hidden md:table-cell">{t("items")}</th>
                    <th className="pb-2 text-start font-medium">{t("total")}</th>
                    <th className="pb-2 text-start font-medium">{t("status")}</th>
                    <th className="pb-2 text-start font-medium hidden sm:table-cell">{t("time")}</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {(stats?.recent_orders ?? []).map((order) => (
                    <tr key={order.id} className="hover:bg-muted/50 transition-colors">
                      <td className="py-3 font-mono text-xs">#{order.order_number}</td>
                      <td className="py-3">{order.customer_name}</td>
                      <td className="py-3 hidden md:table-cell">{order.items_count}</td>
                      <td className="py-3">
                        <MoneyDisplay piastres={order.total} />
                      </td>
                      <td className="py-3">
                        <span className={cn("rounded-full px-2 py-0.5 text-xs font-medium", STATUS_COLORS[order.status] ?? "bg-muted text-muted-foreground")}>
                          {order.status.replace(/_/g, " ")}
                        </span>
                      </td>
                      <td className="py-3 text-muted-foreground text-xs hidden sm:table-cell">
                        {formatDistanceToNow(new Date(order.created_at), {addSuffix: true, locale: dateLocale})}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
