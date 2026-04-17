"use client";

import React from "react";
import {useQueryClient} from "@tanstack/react-query";
import {toast} from "sonner";
import {useNotificationStore} from "@/stores/notificationStore";

type NewOrderEvent = {
  order: {id: number; order_number: string};
};

function runtimeEnv(key: string, fallback: string): string {
  if (typeof window !== "undefined") {
    const w = window as unknown as Record<string, Record<string, string>>;
    if (w.__ENV__?.[key]) return w.__ENV__[key];
  }
  return (process.env[key] as string | undefined) ?? fallback;
}

export function useRealtime(tenantId?: string | number) {
  const qc = useQueryClient();
  const {incrementPendingOrders, incrementUnread} = useNotificationStore();

  React.useEffect(() => {
    if (!tenantId) return;
    if (typeof window === "undefined") return;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let echo: import("laravel-echo").default<any> | null = null;

    const init = async () => {
      try {
        const Pusher = (await import("pusher-js")).default;
        const Echo = (await import("laravel-echo")).default;

        const token = localStorage.getItem("token");

        const reverbKey  = runtimeEnv("NEXT_PUBLIC_REVERB_APP_KEY", "foodapp-key");
        const reverbHost = runtimeEnv("NEXT_PUBLIC_REVERB_HOST", "localhost");
        const reverbPort = Number(runtimeEnv("NEXT_PUBLIC_REVERB_PORT", "8080"));
        const apiUrl     = runtimeEnv("NEXT_PUBLIC_API_URL", "http://localhost");

        echo = new Echo({
          broadcaster: "reverb",
          key: reverbKey,
          wsHost: reverbHost,
          wsPort: reverbPort,
          wssPort: reverbPort,
          forceTLS: false,
          enabledTransports: ["ws"],
          authEndpoint: `${apiUrl}/broadcasting/auth`,
          auth: {headers: {Authorization: `Bearer ${token}`}},
          client: new Pusher(reverbKey, {
            wsHost: reverbHost,
            wsPort: reverbPort,
            forceTLS: false,
            enabledTransports: ["ws"],
            cluster: "mt1",
          }),
        });

        echo.channel(`orders.${tenantId}`).listen("NewOrderPlaced", (e: NewOrderEvent) => {
          qc.invalidateQueries({queryKey: ["orders"]});
          qc.invalidateQueries({queryKey: ["dashboard-stats"]});
          incrementPendingOrders();
          incrementUnread();

          try {
            const audio = new Audio("/notification.mp3");
            audio.play().catch(() => {});
          } catch {}

          toast.success(`New order #${e.order.order_number} received!`);
        });
      } catch (err) {
        console.warn("Realtime connection failed:", err);
      }
    };

    init();

    return () => {
      echo?.disconnect();
    };
  }, [tenantId, qc, incrementPendingOrders, incrementUnread]);
}
