"use client";

import React from "react";
import {useOrders, type Order, type OrderStatus} from "@/hooks/useOrders";
import {OrderCard} from "./OrderCard";
import {OrderDetailModal} from "./OrderDetailModal";
import {Badge} from "@/components/ui/badge";
import {Skeleton} from "@/components/ui/skeleton";

const COLUMNS: {status: OrderStatus; label: string; color: string}[] = [
  {status: "pending", label: "Pending", color: "bg-yellow-500"},
  {status: "confirmed", label: "Confirmed", color: "bg-blue-500"},
  {status: "preparing", label: "Preparing", color: "bg-orange-500"},
  {status: "ready", label: "Ready", color: "bg-teal-500"},
  {status: "out_for_delivery", label: "Out for Delivery", color: "bg-purple-500"},
  {status: "delivered", label: "Delivered", color: "bg-green-500"},
];

export function OrdersKanban() {
  const [selectedOrderId, setSelectedOrderId] = React.useState<number | null>(null);

  const {data, isLoading} = useOrders({});

  const ordersByStatus = React.useMemo(() => {
    const map: Record<string, Order[]> = {};
    COLUMNS.forEach((col) => (map[col.status] = []));
    (data?.data ?? []).forEach((order) => {
      if (map[order.status]) map[order.status].push(order);
    });
    return map;
  }, [data]);

  if (isLoading) {
    return (
      <div className="flex gap-4 overflow-x-auto pb-4">
        {COLUMNS.map((col) => (
          <div key={col.status} className="min-w-56 space-y-2">
            <Skeleton className="h-8" />
            {Array.from({length: 3}).map((_, i) => (
              <Skeleton key={i} className="h-24" />
            ))}
          </div>
        ))}
      </div>
    );
  }

  return (
    <>
      <div className="flex gap-4 overflow-x-auto pb-4">
        {COLUMNS.map((col) => {
          const orders = ordersByStatus[col.status] ?? [];
          return (
            <div key={col.status} className="min-w-56 flex-shrink-0">
              <div className="flex items-center gap-2 mb-3">
                <div className={`h-2 w-2 rounded-full ${col.color}`} />
                <span className="text-sm font-medium">{col.label}</span>
                <Badge variant="secondary" className="ms-auto text-xs">
                  {orders.length}
                </Badge>
              </div>
              <div className="space-y-2">
                {orders.map((order) => (
                  <OrderCard
                    key={order.id}
                    order={order}
                    onClick={() => setSelectedOrderId(order.id)}
                  />
                ))}
                {orders.length === 0 && (
                  <div className="rounded-md border border-dashed p-4 text-center text-xs text-muted-foreground">
                    No orders
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <OrderDetailModal orderId={selectedOrderId} onClose={() => setSelectedOrderId(null)} />
    </>
  );
}
