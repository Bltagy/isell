"use client";

import {create} from "zustand";

type NotificationState = {
  unreadCount: number;
  pendingOrdersCount: number;
  setUnreadCount: (count: number) => void;
  incrementUnread: () => void;
  setPendingOrders: (count: number) => void;
  incrementPendingOrders: () => void;
};

export const useNotificationStore = create<NotificationState>((set) => ({
  unreadCount: 0,
  pendingOrdersCount: 0,
  setUnreadCount: (count) => set({unreadCount: count}),
  incrementUnread: () => set((s) => ({unreadCount: s.unreadCount + 1})),
  setPendingOrders: (count) => set({pendingOrdersCount: count}),
  incrementPendingOrders: () => set((s) => ({pendingOrdersCount: s.pendingOrdersCount + 1})),
}));
