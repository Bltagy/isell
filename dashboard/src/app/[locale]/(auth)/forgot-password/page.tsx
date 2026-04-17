"use client";

import {zodResolver} from "@hookform/resolvers/zod";
import {useMutation} from "@tanstack/react-query";
import {useLocale, useTranslations} from "next-intl";
import Link from "next/link";
import {useForm} from "react-hook-form";
import {toast} from "sonner";
import {z} from "zod";

import {Button, buttonVariants} from "@/components/ui/button";
import {Card, CardContent, CardDescription, CardHeader, CardTitle} from "@/components/ui/card";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {api, type ApiError} from "@/lib/api";

export default function ForgotPasswordPage() {
  const t = useTranslations();
  const locale = useLocale();

  const schema = z.object({
    email: z.string().min(1, t("validation.required")).email(t("validation.email")),
  });

  type FormValues = z.infer<typeof schema>;

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {email: ""},
  });

  const send = useMutation({
    mutationFn: async (values: FormValues) => {
      await api.post("/api/v1/auth/forgot-password", values);
    },
    onSuccess: () => {
      toast.success(t("toast.resetLinkSent"));
    },
    onError: (err: ApiError) => {
      toast.error(err.message);
    },
  });

  return (
    <Card className="w-full max-w-md">
      <CardHeader className="space-y-2">
        <CardTitle className="text-center">{t("auth.forgotPasswordTitle")}</CardTitle>
        <CardDescription className="text-center">{t("auth.forgotPasswordSubtitle")}</CardDescription>
      </CardHeader>
      <CardContent>
        <form className="space-y-4" onSubmit={form.handleSubmit((v) => send.mutate(v))}>
          <div className="space-y-2">
            <Label htmlFor="email">{t("auth.email")}</Label>
            <Input
              id="email"
              type="email"
              autoComplete="email"
              placeholder={t("auth.emailPlaceholder")}
              {...form.register("email")}
            />
            {form.formState.errors.email?.message ? (
              <p className="text-sm text-destructive">{form.formState.errors.email.message}</p>
            ) : null}
          </div>

          <Button type="submit" className="w-full" disabled={send.isPending}>
            {send.isPending ? t("common.loading") : t("auth.sendResetLink")}
          </Button>

          <Link className={buttonVariants({variant: "link", className: "w-full justify-center"})} href={`/${locale}/login`}>
            {t("auth.backToLogin")}
          </Link>
        </form>
      </CardContent>
    </Card>
  );
}

