"use client";

import {useParams, useRouter} from "next/navigation";
import {OrderDetailModal} from "@/components/orders/OrderDetailModal";

export default function OrderDetailPage() {
  const {id} = useParams();
  const router = useRouter();

  return (
    <OrderDetailModal
      orderId={Number(id)}
      onClose={() => router.back()}
    />
  );
}
