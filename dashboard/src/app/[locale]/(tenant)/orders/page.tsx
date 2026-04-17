"use client";

import React from "react";
import {useTranslations} from "next-intl";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {OrdersKanban} from "@/components/orders/OrdersKanban";
import {OrdersTable} from "@/components/orders/OrdersTable";

export default function OrdersPage() {
  const t = useTranslations("orders");

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <Tabs defaultValue="kanban">
        <TabsList>
          <TabsTrigger value="kanban">{t("kanban")}</TabsTrigger>
          <TabsTrigger value="list">{t("list")}</TabsTrigger>
        </TabsList>
        <TabsContent value="kanban" className="mt-4">
          <OrdersKanban />
        </TabsContent>
        <TabsContent value="list" className="mt-4">
          <OrdersTable />
        </TabsContent>
      </Tabs>
    </div>
  );
}
