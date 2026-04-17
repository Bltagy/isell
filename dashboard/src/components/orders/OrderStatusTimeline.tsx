"use client";

import {cn} from "@/lib/utils";
import type {OrderStatus} from "@/hooks/useOrders";
import {Check, X} from "lucide-react";

const STEPS: {status: OrderStatus; label: string}[] = [
  {status: "pending",          label: "Pending"},
  {status: "confirmed",        label: "Confirmed"},
  {status: "preparing",        label: "Preparing"},
  {status: "ready",            label: "Ready"},
  {status: "out_for_delivery", label: "Delivery"},
  {status: "delivered",        label: "Delivered"},
];

const STATUS_ORDER: Record<OrderStatus, number> = {
  pending: 0, confirmed: 1, preparing: 2,
  ready: 3, out_for_delivery: 4, delivered: 5, cancelled: -1,
};

export function OrderStatusTimeline({currentStatus}: {currentStatus: OrderStatus}) {
  const currentIndex = STATUS_ORDER[currentStatus] ?? -1;

  if (currentStatus === "cancelled") {
    return (
      <div className="flex items-center gap-2 rounded-lg bg-destructive/10 border border-destructive/20 px-4 py-3">
        <div className="flex h-7 w-7 items-center justify-center rounded-full bg-destructive/15">
          <X className="h-4 w-4 text-destructive" />
        </div>
        <span className="text-sm font-semibold text-destructive">Order Cancelled</span>
      </div>
    );
  }

  return (
    <div className="flex items-start w-full px-1">
      {STEPS.map((step, i) => {
        const done   = i < currentIndex;
        const active = i === currentIndex;
        const isLast = i === STEPS.length - 1;

        return (
          <div key={step.status} className="flex items-center flex-1 min-w-0">
            {/* Step node */}
            <div className="flex flex-col items-center gap-1.5 flex-shrink-0">
              <div
                className={cn(
                  "flex h-7 w-7 items-center justify-center rounded-full border-2 text-[11px] font-bold transition-all",
                  done   && "border-primary bg-primary text-white shadow-sm",
                  active && "border-primary bg-white text-primary shadow-md ring-2 ring-primary/20",
                  !done && !active && "border-muted-foreground/25 bg-muted/30 text-muted-foreground/40"
                )}
              >
                {done ? <Check className="h-3.5 w-3.5" /> : i + 1}
              </div>
              <span
                className={cn(
                  "text-[9px] font-medium text-center leading-tight w-10",
                  active && "text-primary font-semibold",
                  done   && "text-muted-foreground",
                  !done && !active && "text-muted-foreground/40"
                )}
              >
                {step.label}
              </span>
            </div>

            {/* Connector */}
            {!isLast && (
              <div className={cn(
                "flex-1 h-0.5 mx-0.5 mb-5 rounded-full transition-colors",
                i < currentIndex ? "bg-primary" : "bg-muted-foreground/15"
              )} />
            )}
          </div>
        );
      })}
    </div>
  );
}
