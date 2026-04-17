"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {Card, CardContent} from "@/components/ui/card";
import {Button} from "@/components/ui/button";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {useUpdateOrderStatus, useAssignDriver, type Order, type OrderStatus} from "@/hooks/useOrders";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {formatDistanceToNow} from "date-fns";
import {toast} from "sonner";

type Driver = {id: number; name: string};

type OrderCardProps = {
  order: Order;
  onClick: () => void;
};

const NEXT_STATUS: Partial<Record<OrderStatus, OrderStatus>> = {
  pending: "confirmed",
  confirmed: "preparing",
  preparing: "ready",
  ready: "out_for_delivery",
  out_for_delivery: "delivered",
};

export function OrderCard({order, onClick}: OrderCardProps) {
  const t = useTranslations("orders");
  const updateStatus = useUpdateOrderStatus();
  const assignDriver = useAssignDriver();

  const {data: drivers} = useQuery<Driver[]>({
    queryKey: ["drivers-list"],
    queryFn: async () => {
      const res = await api.get<{data: Driver[]}>("/api/v1/admin/drivers");
      return res.data.data ?? [];
    },
    enabled: order.status === "ready",
  });

  const handleAction = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const next = NEXT_STATUS[order.status];
    if (!next) return;
    try {
      await updateStatus.mutateAsync({id: order.id, status: next});
      toast.success("Status updated");
    } catch {
      toast.error("Failed");
    }
  };

  const handleAssign = async (driverId: string | null) => {
    if (!driverId) return;
    try {
      await assignDriver.mutateAsync({orderId: order.id, driverId: Number(driverId)});
      await updateStatus.mutateAsync({id: order.id, status: "out_for_delivery"});
      toast.success("Driver assigned");
    } catch {
      toast.error("Failed");
    }
  };

  const actionLabel: Partial<Record<OrderStatus, string>> = {
    pending: t("confirm"),
    confirmed: t("startPreparing"),
    preparing: t("markReady"),
    out_for_delivery: t("markDelivered"),
  };

  return (
    <Card
      className="cursor-pointer hover:shadow-md transition-shadow"
      onClick={onClick}
    >
      <CardContent className="p-3 space-y-2">
        <div className="flex items-center justify-between">
          <span className="font-mono text-xs font-semibold">#{order.order_number}</span>
          <MoneyDisplay piastres={order.total} className="text-sm font-medium" />
        </div>
        <p className="text-sm truncate">{order.customer_name}</p>
        <p className="text-xs text-muted-foreground">{order.items.length} items · {formatDistanceToNow(new Date(order.created_at), {addSuffix: true})}</p>

        {order.status === "ready" ? (
          <div onClick={(e) => e.stopPropagation()}>
            <Select onValueChange={handleAssign}>
              <SelectTrigger className="h-7 text-xs">
                <SelectValue placeholder={t("assignDriver")} />
              </SelectTrigger>
              <SelectContent>
                {(drivers ?? []).map((d) => (
                  <SelectItem key={d.id} value={d.id.toString()}>{d.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        ) : actionLabel[order.status] ? (
          <Button
            size="sm"
            className="w-full h-7 text-xs"
            onClick={handleAction}
            disabled={updateStatus.isPending}
          >
            {actionLabel[order.status]}
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}
