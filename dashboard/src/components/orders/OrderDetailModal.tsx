"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {Sheet, SheetContent, SheetHeader, SheetTitle} from "@/components/ui/sheet";
import {Button} from "@/components/ui/button";
import {Skeleton} from "@/components/ui/skeleton";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {Separator} from "@/components/ui/separator";
import {Badge} from "@/components/ui/badge";
import {useOrder, useUpdateOrderStatus, useAssignDriver, type OrderStatus} from "@/hooks/useOrders";
import {useQuery} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {MoneyDisplay} from "@/components/common/MoneyDisplay";
import {OrderStatusBadge} from "./OrderStatusBadge";
import {OrderStatusTimeline} from "./OrderStatusTimeline";
import {toast} from "sonner";
import {Phone, MapPin, Printer, User, Package} from "lucide-react";

type Driver = {id: number; name: string};

type OrderDetailModalProps = {
  orderId: number | null;
  onClose: () => void;
};

const NEXT_STATUS: Partial<Record<OrderStatus, OrderStatus>> = {
  pending:          "confirmed",
  confirmed:        "preparing",
  preparing:        "ready",
  ready:            "out_for_delivery",
  out_for_delivery: "delivered",
};

const NEXT_LABEL: Partial<Record<OrderStatus, string>> = {
  pending:          "Confirm Order",
  confirmed:        "Start Preparing",
  preparing:        "Mark Ready",
  ready:            "Out for Delivery",
  out_for_delivery: "Mark Delivered",
};

// ── Row helper ────────────────────────────────────────────────────────────────
function Row({label, value, bold}: {label: string; value: React.ReactNode; bold?: boolean}) {
  return (
    <div className="flex items-center justify-between py-1.5 text-sm">
      <span className={bold ? "font-semibold" : "text-muted-foreground"}>{label}</span>
      <span className={bold ? "font-bold text-base" : "font-medium"}>{value}</span>
    </div>
  );
}

// ── Section header ────────────────────────────────────────────────────────────
function SectionTitle({icon: Icon, label}: {icon: React.ElementType; label: string}) {
  return (
    <div className="flex items-center gap-2 mb-3">
      <div className="flex h-6 w-6 items-center justify-center rounded-md bg-primary/10">
        <Icon className="h-3.5 w-3.5 text-primary" />
      </div>
      <p className="text-sm font-semibold">{label}</p>
    </div>
  );
}

export function OrderDetailModal({orderId, onClose}: OrderDetailModalProps) {
  const t = useTranslations("orders");
  const {data: order, isLoading} = useOrder(orderId ?? 0);
  const updateStatus = useUpdateOrderStatus();
  const assignDriver = useAssignDriver();

  const {data: drivers} = useQuery<Driver[]>({
    queryKey: ["drivers-list"],
    queryFn: async () => {
      const res = await api.get<{data: Driver[]}>("/api/v1/admin/drivers");
      return res.data.data ?? [];
    },
  });

  const handleStatusChange = async () => {
    if (!order) return;
    const next = NEXT_STATUS[order.status];
    if (!next) return;
    try {
      await updateStatus.mutateAsync({id: order.id, status: next});
      toast.success("Status updated");
    } catch {
      toast.error("Failed to update status");
    }
  };

  const handleAssignDriver = async (driverId: string | null) => {
    if (!driverId || !order) return;
    try {
      await assignDriver.mutateAsync({orderId: order.id, driverId: Number(driverId)});
      toast.success("Driver assigned");
    } catch {
      toast.error("Failed to assign driver");
    }
  };

  const handlePrint = () => {
    if (!order) return;
    const egp = (p: number) => `EGP ${(p / 100).toFixed(2)}`;
    const date = new Date(order.created_at).toLocaleString("en-GB");
    const itemRows = order.items.map((item) => {
      const name = item.product_name || item.name || "—";
      const total = item.total_price ?? item.subtotal ?? 0;
      return `<tr><td>${item.quantity}×</td><td>${name}</td><td class="r">${egp(total)}</td></tr>`;
    }).join("");
    const discountRow = order.discount > 0
      ? `<tr><td colspan="2">Discount</td><td class="r">−${egp(order.discount)}</td></tr>` : "";
    const html = `<!DOCTYPE html><html dir="ltr"><head><meta charset="utf-8"/>
<title>Receipt #${order.order_number}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;font-size:13px;width:80mm;margin:0 auto;padding:8mm 4mm;color:#000}
.c{text-align:center}.b{font-weight:bold}.lg{font-size:16px}
hr{border:none;border-top:1px dashed #000;margin:6px 0}
table{width:100%;border-collapse:collapse}
td{padding:2px 0;vertical-align:top}
td.r{text-align:right;white-space:nowrap}
td:first-child{width:28px}
.tot td{padding:1px 0}
.tot-row td{font-weight:bold;font-size:15px;padding-top:4px}
@media print{@page{margin:0;size:80mm auto}body{padding:4mm}}
</style></head><body>
<div class="c b lg">🍔 Food App</div>
<div class="c" style="font-size:11px;margin-top:2px">Order Receipt</div>
<hr/>
<table>
  <tr><td>Order #</td><td class="r b">${order.order_number}</td></tr>
  <tr><td>Date</td><td class="r">${date}</td></tr>
  <tr><td>Status</td><td class="r">${order.status.replace(/_/g," ")}</td></tr>
</table>
<hr/>
<div class="b" style="margin-bottom:4px">Customer</div>
<div>${order.customer_name || "—"}</div>
${order.customer_phone ? `<div>${order.customer_phone}</div>` : ""}
${order.delivery_address ? `<div style="font-size:11px;margin-top:2px">${order.delivery_address}</div>` : ""}
<hr/>
<div class="b" style="margin-bottom:4px">Items</div>
<table>${itemRows}</table>
<hr/>
<table class="tot">
  <tr><td>Subtotal</td><td class="r">${egp(order.subtotal)}</td></tr>
  <tr><td>Delivery</td><td class="r">${egp(order.delivery_fee)}</td></tr>
  ${discountRow}
  <tr><td>Tax</td><td class="r">${egp(order.tax)}</td></tr>
  <tr class="tot-row"><td>TOTAL</td><td class="r">${egp(order.total)}</td></tr>
</table>
<hr/>
<table>
  <tr><td>Payment</td><td class="r">${(order.payment_method||"").replace(/_/g," ")}</td></tr>
  <tr><td>Status</td><td class="r">${order.payment_status||""}</td></tr>
</table>
${order.notes ? `<hr/><div class="b">Notes</div><div style="font-size:11px">${order.notes}</div>` : ""}
<hr/>
<div class="c" style="font-size:11px;margin-top:4px">Thank you for your order!</div>
</body></html>`;
    const win = window.open("", "_blank", "width=420,height=640");
    if (!win) return;
    win.document.write(html);
    win.document.close();
    win.focus();
    setTimeout(() => { win.print(); win.close(); }, 350);
  };

  return (
    <Sheet open={!!orderId} onOpenChange={(o) => !o && onClose()}>
      {/* Wider sheet so prices don't clip */}
      <SheetContent className="w-full sm:max-w-xl flex flex-col p-0" side="right">

        {/* ── Sticky header ─────────────────────────────────────── */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background sticky top-0 z-10">
          <SheetHeader className="text-start">
            <SheetTitle className="text-base">{t("orderDetail")}</SheetTitle>
          </SheetHeader>
        </div>

        {/* ── Scrollable body ───────────────────────────────────── */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-5">
          {isLoading ? (
            <div className="space-y-4">
              {Array.from({length: 6}).map((_, i) => <Skeleton key={i} className="h-10" />)}
            </div>
          ) : order ? (
            <>
              {/* Order meta */}
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="font-mono text-sm font-semibold">
                    {t("orderNumber")}{order.order_number}
                  </p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {new Date(order.created_at).toLocaleString()}
                  </p>
                </div>
                <OrderStatusBadge status={order.status} />
              </div>

              {/* Timeline */}
              <div className="bg-muted/30 rounded-xl p-3">
                <OrderStatusTimeline currentStatus={order.status} />
              </div>

              <Separator />

              {/* Customer */}
              <div>
                <SectionTitle icon={User} label={t("customerInfo")} />
                <div className="bg-muted/30 rounded-xl p-3 space-y-2">
                  <p className="text-sm font-medium">{order.customer_name || "—"}</p>
                  {order.customer_phone && (
                    <a
                      href={`tel:${order.customer_phone}`}
                      className="flex items-center gap-1.5 text-sm text-primary hover:underline w-fit"
                    >
                      <Phone className="h-3.5 w-3.5 flex-shrink-0" />
                      <span dir="ltr">{order.customer_phone}</span>
                    </a>
                  )}
                  {order.delivery_address && (
                    <div className="flex items-start gap-1.5 text-sm text-muted-foreground">
                      <MapPin className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
                      <span>{order.delivery_address}</span>
                    </div>
                  )}
                </div>
              </div>

              <Separator />

              {/* Items */}
              <div>
                <SectionTitle icon={Package} label={t("orderItems")} />
                <div className="space-y-2">
                  {order.items.map((item) => {
                    const itemName = item.product_name || item.name || "—";
                    const itemTotal = item.total_price ?? item.subtotal ?? 0;
                    const opts = (item.options ?? []) as Record<string, unknown>[];
                    return (
                      <div key={item.id} className="flex items-start justify-between gap-3 text-sm py-1.5 border-b border-dashed last:border-0">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <Badge variant="secondary" className="text-xs px-1.5 py-0 h-5 flex-shrink-0">
                              ×{item.quantity}
                            </Badge>
                            <span className="font-medium truncate">{itemName}</span>
                          </div>
                          {opts.map((opt, i) => {
                            const groupName = String(opt.name_en ?? opt.name ?? "");
                            const subItems = (opt.items ?? []) as {name_en?: string; extra_price?: number}[];
                            return subItems.map((it, j) => (
                              <p key={`${i}-${j}`} className="text-xs text-muted-foreground ms-7 mt-0.5">
                                + {groupName}: {it.name_en ?? ""}
                                {it.extra_price ? ` (+EGP ${(it.extra_price / 100).toFixed(2)})` : ""}
                              </p>
                            ));
                          })}
                        </div>
                        <span className="font-semibold text-sm flex-shrink-0 tabular-nums">
                          <MoneyDisplay piastres={itemTotal} />
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Price breakdown */}
              <div className="bg-muted/30 rounded-xl p-3 space-y-0.5">
                <Row label={t("subtotal")}    value={<MoneyDisplay piastres={order.subtotal} />} />
                {order.discount > 0 && (
                  <Row
                    label={t("discount")}
                    value={<span className="text-green-600">−<MoneyDisplay piastres={order.discount} /></span>}
                  />
                )}
                <Row label={t("deliveryFee")} value={<MoneyDisplay piastres={order.delivery_fee} />} />
                <Row label={t("tax")}         value={<MoneyDisplay piastres={order.tax} />} />
                <Separator className="my-2" />
                <Row label="Total" value={<MoneyDisplay piastres={order.total} />} bold />
              </div>

              <Separator />

              {/* Payment */}
              <div>
                <p className="text-sm font-semibold mb-2">{t("paymentInfo")}</p>
                <div className="bg-muted/30 rounded-xl p-3 space-y-0.5">
                  <Row
                    label={t("paymentMethod")}
                    value={<span className="capitalize">{order.payment_method?.replace(/_/g, " ")}</span>}
                  />
                  <Row
                    label={t("paymentStatus")}
                    value={
                      <Badge
                        variant={order.payment_status === "paid" ? "default" : "secondary"}
                        className="capitalize text-xs"
                      >
                        {order.payment_status}
                      </Badge>
                    }
                  />
                </div>
              </div>

              {/* Driver assignment */}
              {["ready", "out_for_delivery"].includes(order.status) && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm font-semibold mb-2">{t("driverAssignment")}</p>
                    <Select
                      value={order.driver_id?.toString() ?? ""}
                      onValueChange={handleAssignDriver}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder={t("selectDriver")} />
                      </SelectTrigger>
                      <SelectContent>
                        {(drivers ?? []).map((d) => (
                          <SelectItem key={d.id} value={d.id.toString()}>
                            {d.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </>
              )}

              {/* Notes */}
              {order.notes && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm font-semibold mb-1">{t("notes")}</p>
                    <p className="text-sm text-muted-foreground bg-muted/30 rounded-lg px-3 py-2">
                      {order.notes}
                    </p>
                  </div>
                </>
              )}
            </>
          ) : null}
        </div>

        {/* ── Sticky footer actions ─────────────────────────────── */}
        {order && (
          <div className="border-t px-6 py-4 bg-background flex gap-2">
            {NEXT_STATUS[order.status] && (
              <Button
                className="flex-1"
                onClick={handleStatusChange}
                disabled={updateStatus.isPending}
              >
                {updateStatus.isPending ? "Updating…" : NEXT_LABEL[order.status]}
              </Button>
            )}
            <Button
              variant="outline"
              size="icon"
              onClick={handlePrint}
              aria-label={t("printReceipt")}
            >
              <Printer className="h-4 w-4" />
            </Button>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
