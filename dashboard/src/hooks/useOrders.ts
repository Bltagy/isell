import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api} from "@/lib/api";

export type OrderStatus =
  | "pending"
  | "confirmed"
  | "preparing"
  | "ready"
  | "out_for_delivery"
  | "delivered"
  | "cancelled";

export type OrderItem = {
  id: number;
  product_name: string;
  name?: string; // alias returned by API
  quantity: number;
  unit_price: number;
  total_price?: number;  // alias for subtotal
  subtotal?: number;
  options?: Record<string, unknown>[];
};

export type Order = {
  id: number;
  order_number: string;
  status: OrderStatus;
  customer_name: string;
  customer_phone: string;
  delivery_address: string;
  items: OrderItem[];
  subtotal: number;
  discount: number;
  delivery_fee: number;
  tax: number;
  total: number;
  payment_method: string;
  payment_status: string;
  driver_id?: number;
  driver_name?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
};

type OrdersParams = {
  page?: number;
  status?: string;
  search?: string;
  payment_method?: string;
  from?: string;
  to?: string;
};

type OrdersResponse = {
  data: Order[];
  meta: {current_page: number; last_page: number; total: number};
};

export function useOrders(params: OrdersParams = {}) {
  return useQuery<OrdersResponse>({
    queryKey: ["orders", params],
    queryFn: async () => {
      const res = await api.get<OrdersResponse>("/api/v1/admin/orders", {params});
      return res.data;
    },
  });
}

export function useOrder(id: number) {
  return useQuery<Order>({
    queryKey: ["orders", id],
    queryFn: async () => {
      const res = await api.get<{data: Order}>(`/api/v1/admin/orders/${id}`);
      return res.data.data;
    },
    enabled: !!id,
  });
}

export function useUpdateOrderStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({id, status}: {id: number; status: OrderStatus}) => {
      const res = await api.put(`/api/v1/admin/orders/${id}/status`, {status});
      return res.data;
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["orders"]});
    },
  });
}

export function useAssignDriver() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({orderId, driverId}: {orderId: number; driverId: number}) => {
      const res = await api.put(`/api/v1/admin/orders/${orderId}/assign-driver`, {driver_id: driverId});
      return res.data;
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["orders"]});
    },
  });
}
