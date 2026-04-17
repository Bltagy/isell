"use client";

import React from "react";
import {useTranslations, useLocale} from "next-intl";
import {useParams, useRouter} from "next/navigation";
import {useQuery, useMutation, useQueryClient} from "@tanstack/react-query";
import {api} from "@/lib/api";
import {Button} from "@/components/ui/button";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {Switch} from "@/components/ui/switch";
import {Select, SelectContent, SelectItem, SelectTrigger, SelectValue} from "@/components/ui/select";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {Card, CardContent} from "@/components/ui/card";
import {BilingualInput} from "@/components/common/BilingualInput";
import {toast} from "sonner";
import {ArrowLeft, Plus, Trash2} from "lucide-react";

type Category = {id: number; name_en: string};

type OptionItem = {id?: number; name_en: string; name_ar: string; extra_price: string};
type OptionGroup = {id?: number; name_en: string; name_ar: string; type: "single" | "multiple"; is_required: boolean; max_selections: string; items: OptionItem[]};

type ProductForm = {
  name_en: string; name_ar: string;
  description_en: string; description_ar: string;
  category_id: string;
  price: string; discount_price: string;
  prep_time: string; calories: string;
  is_featured: boolean; is_available: boolean;
  sort_order: string;
  option_groups: OptionGroup[];
};

const DEFAULT_FORM: ProductForm = {
  name_en: "", name_ar: "", description_en: "", description_ar: "",
  category_id: "", price: "", discount_price: "", prep_time: "", calories: "",
  is_featured: false, is_available: true, sort_order: "0", option_groups: [],
};

export default function ProductFormPage() {
  const t = useTranslations("menu");
  const locale = useLocale();
  const router = useRouter();
  const params = useParams();
  const qc = useQueryClient();
  const isNew = params.id === "new";
  const productId = isNew ? null : Number(params.id);

  const [form, setForm] = React.useState<ProductForm>(DEFAULT_FORM);

  const {data: categories} = useQuery<Category[]>({
    queryKey: ["categories"],
    queryFn: async () => {
      const res = await api.get<{data: Category[]}>("/api/v1/admin/categories");
      return res.data.data ?? [];
    },
  });

  const {isLoading} = useQuery({
    queryKey: ["product", productId],
    queryFn: async () => {
      const res = await api.get<{data: ProductForm & {option_groups: OptionGroup[]}}>(`/api/v1/admin/products/${productId}`);
      const d = res.data.data;
      setForm({
        name_en: d.name_en, name_ar: d.name_ar,
        description_en: d.description_en, description_ar: d.description_ar,
        category_id: String((d as unknown as {category_id: number}).category_id),
        price: String((d as unknown as {price: number}).price / 100),
        discount_price: String((d as unknown as {discount_price: number}).discount_price / 100 || ""),
        prep_time: String((d as unknown as {prep_time: number}).prep_time || ""),
        calories: String((d as unknown as {calories: number}).calories || ""),
        is_featured: (d as unknown as {is_featured: boolean}).is_featured,
        is_available: (d as unknown as {is_available: boolean}).is_available,
        sort_order: String((d as unknown as {sort_order: number}).sort_order || 0),
        option_groups: d.option_groups ?? [],
      });
      return d;
    },
    enabled: !isNew && !!productId,
  });

  const save = useMutation({
    mutationFn: async () => {
      const payload = {
        ...form,
        price: Math.round(Number(form.price) * 100),
        discount_price: form.discount_price ? Math.round(Number(form.discount_price) * 100) : null,
        prep_time: Number(form.prep_time) || null,
        calories: Number(form.calories) || null,
        sort_order: Number(form.sort_order),
        category_id: Number(form.category_id),
        option_groups: form.option_groups.map((g) => ({
          ...g,
          max_selections: Number(g.max_selections) || null,
          items: g.items.map((item) => ({...item, extra_price: Math.round(Number(item.extra_price) * 100)})),
        })),
      };
      if (isNew) return api.post("/api/v1/admin/products", payload);
      return api.put(`/api/v1/admin/products/${productId}`, payload);
    },
    onSuccess: () => {
      qc.invalidateQueries({queryKey: ["products"]});
      toast.success("Saved");
      router.push(`/${locale}/menu/products`);
    },
    onError: () => toast.error("Failed to save"),
  });

  const addGroup = () => {
    setForm((f) => ({...f, option_groups: [...f.option_groups, {name_en: "", name_ar: "", type: "single", is_required: false, max_selections: "", items: []}]}));
  };

  const removeGroup = (i: number) => {
    setForm((f) => ({...f, option_groups: f.option_groups.filter((_, idx) => idx !== i)}));
  };

  const addItem = (gi: number) => {
    setForm((f) => {
      const groups = [...f.option_groups];
      groups[gi] = {...groups[gi], items: [...groups[gi].items, {name_en: "", name_ar: "", extra_price: "0"}]};
      return {...f, option_groups: groups};
    });
  };

  const removeItem = (gi: number, ii: number) => {
    setForm((f) => {
      const groups = [...f.option_groups];
      groups[gi] = {...groups[gi], items: groups[gi].items.filter((_, idx) => idx !== ii)};
      return {...f, option_groups: groups};
    });
  };

  const updateGroup = (i: number, key: keyof OptionGroup, value: unknown) => {
    setForm((f) => {
      const groups = [...f.option_groups];
      groups[i] = {...groups[i], [key]: value};
      return {...f, option_groups: groups};
    });
  };

  const updateItem = (gi: number, ii: number, key: keyof OptionItem, value: string) => {
    setForm((f) => {
      const groups = [...f.option_groups];
      const items = [...groups[gi].items];
      items[ii] = {...items[ii], [key]: value};
      groups[gi] = {...groups[gi], items};
      return {...f, option_groups: groups};
    });
  };

  return (
    <div className="space-y-4 max-w-3xl">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => router.back()} aria-label="Back">
          <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
        </Button>
        <h1 className="text-2xl font-bold">{isNew ? t("addProduct") : t("editProduct")}</h1>
      </div>

      <Tabs defaultValue="basic">
        <TabsList>
          <TabsTrigger value="basic">{t("basicInfo")}</TabsTrigger>
          <TabsTrigger value="options">{t("options")}</TabsTrigger>
        </TabsList>

        <TabsContent value="basic" className="mt-4">
          <Card>
            <CardContent className="pt-6 space-y-4">
              <div>
                <Label>Name</Label>
                <BilingualInput valueEn={form.name_en} valueAr={form.name_ar} onChangeEn={(v) => setForm((f) => ({...f, name_en: v}))} onChangeAr={(v) => setForm((f) => ({...f, name_ar: v}))} />
              </div>
              <div>
                <Label>Description</Label>
                <BilingualInput multiline valueEn={form.description_en} valueAr={form.description_ar} onChangeEn={(v) => setForm((f) => ({...f, description_en: v}))} onChangeAr={(v) => setForm((f) => ({...f, description_ar: v}))} />
              </div>
              <div>
                <Label>{t("category")}</Label>
                <Select value={form.category_id} onValueChange={(v) => setForm((f) => ({...f, category_id: v ?? ""}))}>
                  <SelectTrigger><SelectValue placeholder="Select category" /></SelectTrigger>
                  <SelectContent>
                    {(categories ?? []).map((c) => <SelectItem key={c.id} value={c.id.toString()}>{c.name_en}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div><Label>{t("price")}</Label><Input type="number" step="0.01" value={form.price} onChange={(e) => setForm((f) => ({...f, price: e.target.value}))} /></div>
                <div><Label>{t("discountPrice")}</Label><Input type="number" step="0.01" value={form.discount_price} onChange={(e) => setForm((f) => ({...f, discount_price: e.target.value}))} /></div>
                <div><Label>{t("prepTime")}</Label><Input type="number" value={form.prep_time} onChange={(e) => setForm((f) => ({...f, prep_time: e.target.value}))} /></div>
                <div><Label>{t("calories")}</Label><Input type="number" value={form.calories} onChange={(e) => setForm((f) => ({...f, calories: e.target.value}))} /></div>
              </div>
              <div className="flex gap-6">
                <div className="flex items-center gap-2"><Switch checked={form.is_available} onCheckedChange={(v) => setForm((f) => ({...f, is_available: v}))} /><Label>{t("isAvailable")}</Label></div>
                <div className="flex items-center gap-2"><Switch checked={form.is_featured} onCheckedChange={(v) => setForm((f) => ({...f, is_featured: v}))} /><Label>{t("isFeatured")}</Label></div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="options" className="mt-4 space-y-4">
          {form.option_groups.map((group, gi) => (
            <Card key={gi}>
              <CardContent className="pt-4 space-y-3">
                <div className="flex items-center justify-between">
                  <p className="font-medium text-sm">Group {gi + 1}</p>
                  <Button variant="ghost" size="icon" onClick={() => removeGroup(gi)} className="text-destructive"><Trash2 className="h-4 w-4" /></Button>
                </div>
                <BilingualInput valueEn={group.name_en} valueAr={group.name_ar} onChangeEn={(v) => updateGroup(gi, "name_en", v)} onChangeAr={(v) => updateGroup(gi, "name_ar", v)} />
                <div className="flex gap-4">
                  <Select value={group.type} onValueChange={(v) => updateGroup(gi, "type", v)}>
                    <SelectTrigger className="w-36"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="single">{t("single")}</SelectItem>
                      <SelectItem value="multiple">{t("multiple")}</SelectItem>
                    </SelectContent>
                  </Select>
                  <div className="flex items-center gap-2"><Switch checked={group.is_required} onCheckedChange={(v) => updateGroup(gi, "is_required", v)} /><Label>{t("isRequired")}</Label></div>
                </div>
                <div className="space-y-2">
                  {group.items.map((item, ii) => (
                    <div key={ii} className="flex gap-2 items-center">
                      <Input placeholder="EN" value={item.name_en} onChange={(e) => updateItem(gi, ii, "name_en", e.target.value)} className="flex-1" />
                      <Input placeholder="AR" dir="rtl" value={item.name_ar} onChange={(e) => updateItem(gi, ii, "name_ar", e.target.value)} className="flex-1" />
                      <Input type="number" step="0.01" placeholder="Extra" value={item.extra_price} onChange={(e) => updateItem(gi, ii, "extra_price", e.target.value)} className="w-24" />
                      <Button variant="ghost" size="icon" onClick={() => removeItem(gi, ii)} className="text-destructive"><Trash2 className="h-3 w-3" /></Button>
                    </div>
                  ))}
                  <Button variant="outline" size="sm" onClick={() => addItem(gi)} className="gap-1"><Plus className="h-3 w-3" />{t("addItem")}</Button>
                </div>
              </CardContent>
            </Card>
          ))}
          <Button variant="outline" onClick={addGroup} className="gap-2"><Plus className="h-4 w-4" />{t("addOptionGroup")}</Button>
        </TabsContent>
      </Tabs>

      <div className="flex gap-3">
        <Button onClick={() => save.mutate()} disabled={save.isPending}>Save Product</Button>
        <Button variant="outline" onClick={() => router.back()}>Cancel</Button>
      </div>
    </div>
  );
}
