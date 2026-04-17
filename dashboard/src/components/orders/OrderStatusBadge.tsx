"use client";

import {cn} from "@/lib/utils";
import type {OrderStatus} from "@/hooks/useOrders";

const STATUS_STYLES: Record<OrderStatus, string> = {
  pending: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
  confirmed: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
  preparing: "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400",
  ready: "bg-teal-100 text-teal-800 dark:bg-teal-900/30 dark:text-teal-400",
  out_for_delivery: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400",
  delivered: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
  cancelled: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
};

const STATUS_LABELS: Record<OrderStatus, string> = {
  pending: "Pending",
  confirmed: "Confirmed",
  preparing: "Preparing",
  ready: "Ready",
  out_for_delivery: "Out for Delivery",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

export function OrderStatusBadge({status}: {status: OrderStatus}) {
  return (
    <span className={cn("rounded-full px-2 py-0.5 text-xs font-medium", STATUS_STYLES[status])}>
      {STATUS_LABELS[status] ?? status}
    </span>
  );
}
