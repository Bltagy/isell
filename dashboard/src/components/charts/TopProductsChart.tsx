"use client";

import {BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid} from "recharts";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Skeleton} from "@/components/ui/skeleton";

type TopProduct = {name: string; orders: number; image?: string};

export function TopProductsChart() {
  const {data, isLoading} = useQuery<TopProduct[]>({
    queryKey: ["top-products-chart"],
    queryFn: async () => {
      const res = await api.get<{data: {top_products: TopProduct[]}}>("/api/v1/admin/dashboard");
      return res.data.data?.top_products ?? [];
    },
  });

  if (isLoading) return <Skeleton className="h-64 w-full" />;

  return (
    <ResponsiveContainer width="100%" height={240}>
      <BarChart data={data ?? []} layout="vertical">
        <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
        <XAxis type="number" tick={{fontSize: 11}} />
        <YAxis dataKey="name" type="category" width={100} tick={{fontSize: 11}} />
        <Tooltip />
        <Bar dataKey="orders" fill="#FF6B35" radius={[0, 4, 4, 0]} name="Orders" />
      </BarChart>
    </ResponsiveContainer>
  );
}
