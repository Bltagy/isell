"use client";

import {BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer} from "recharts";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Skeleton} from "@/components/ui/skeleton";

type OrdersPoint = {date: string; orders: number};

export function OrdersChart() {
  const {data, isLoading} = useQuery<OrdersPoint[]>({
    queryKey: ["orders-chart"],
    queryFn: async () => {
      const res = await api.get<{data: {orders_chart: OrdersPoint[]}}>("/api/v1/admin/dashboard");
      return res.data.data?.orders_chart ?? [];
    },
  });

  if (isLoading) return <Skeleton className="h-48 w-full" />;

  return (
    <ResponsiveContainer width="100%" height={200}>
      <BarChart data={data ?? []}>
        <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
        <XAxis dataKey="date" tick={{fontSize: 11}} />
        <YAxis tick={{fontSize: 11}} />
        <Tooltip />
        <Bar dataKey="orders" fill="#FF6B35" radius={[4, 4, 0, 0]} name="Orders" />
      </BarChart>
    </ResponsiveContainer>
  );
}
