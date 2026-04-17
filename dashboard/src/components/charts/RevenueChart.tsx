"use client";

import React from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {useTranslations} from "next-intl";
import {Button} from "@/components/ui/button";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Skeleton} from "@/components/ui/skeleton";

type ChartPoint = {date: string; orders: number; revenue: number};

type Period = 7 | 30 | 90;

export function RevenueChart() {
  const t = useTranslations("dashboard");
  const [period, setPeriod] = React.useState<Period>(30);

  const {data, isLoading} = useQuery<ChartPoint[]>({
    queryKey: ["revenue-chart", period],
    queryFn: async () => {
      const res = await api.get<{data: {orders_chart: ChartPoint[]}}>("/api/v1/admin/dashboard");
      // Backend returns the full dashboard object — extract orders_chart sub-array
      return (res.data.data?.orders_chart ?? []).slice(-period);
    },
  });

  if (isLoading) return <Skeleton className="h-64 w-full" />;

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        {([7, 30, 90] as Period[]).map((p) => (
          <Button
            key={p}
            variant={period === p ? "default" : "outline"}
            size="sm"
            onClick={() => setPeriod(p)}
          >
            {p}d
          </Button>
        ))}
      </div>
      <ResponsiveContainer width="100%" height={240}>
        <LineChart data={data ?? []}>
          <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
          <XAxis dataKey="date" tick={{fontSize: 11}} />
          <YAxis yAxisId="left" tick={{fontSize: 11}} />
          <YAxis yAxisId="right" orientation="right" tick={{fontSize: 11}} />
          <Tooltip />
          <Legend />
          <Line yAxisId="left" type="monotone" dataKey="orders" stroke="#FF6B35" strokeWidth={2} dot={false} name="Orders" />
          <Line yAxisId="right" type="monotone" dataKey="revenue" stroke="#6366f1" strokeWidth={2} dot={false} name="Revenue (EGP)" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
