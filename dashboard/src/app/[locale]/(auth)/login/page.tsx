"use client";

import {zodResolver} from "@hookform/resolvers/zod";
import {useMutation} from "@tanstack/react-query";
import {useLocale, useTranslations} from "next-intl";
import Image from "next/image";
import Link from "next/link";
import {useRouter, useSearchParams} from "next/navigation";
import React, {Suspense} from "react";
import {useForm} from "react-hook-form";
import {toast} from "sonner";
import {z} from "zod";

import {Button, buttonVariants} from "@/components/ui/button";
import {Card, CardContent, CardDescription, CardHeader, CardTitle} from "@/components/ui/card";
import {Checkbox} from "@/components/ui/checkbox";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";
import {api, type ApiError} from "@/lib/api";
import {setToken} from "@/lib/auth";

type LoginResponse = {data: {user: unknown; token: string}};

const schema = z.object({
  email: z.string().min(1).email(),
  password: z.string().min(6),
  remember: z.boolean(),
});
type FormValues = z.infer<typeof schema>;

function LoginForm() {
  const t = useTranslations();
  const locale = useLocale();
  const router = useRouter();
  const searchParams = useSearchParams();

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {email: "", password: "", remember: true},
  });

  const login = useMutation({
    mutationFn: async (values: FormValues) => {
      const res = await api.post<LoginResponse>("/api/v1/auth/login", {
        email: values.email,
        password: values.password,
        remember: values.remember,
      });
      return res.data;
    },
    onSuccess: (data) => {
      if (data?.data?.token) {
        setToken(data.data.token);
      }
      toast.success(t("toast.loginSuccess"));
      const next = searchParams.get("next");
      router.replace(next ? `/${locale}${next}` : `/${locale}/dashboard`);
    },
    onError: (err: ApiError) => {
      toast.error(err.message);
    },
  });

  const logoUrl = "/logo.svg";

  return (
    <Card className="w-full max-w-md">
      <CardHeader className="space-y-3">
        <div className="flex items-center justify-center">
          <Image src={logoUrl} alt="Logo" width={64} height={64} priority />
        </div>
        <CardTitle className="text-center">{t("auth.loginTitle")}</CardTitle>
        <CardDescription className="text-center">{t("auth.loginSubtitle")}</CardDescription>
      </CardHeader>
      <CardContent>
        <form
          className="space-y-4"
          onSubmit={form.handleSubmit((values) => login.mutate(values))}
          aria-label="Login form"
        >
          <div className="space-y-2">
            <Label htmlFor="email">{t("auth.email")}</Label>
            <Input
              id="email"
              type="email"
              autoComplete="email"
              placeholder={t("auth.emailPlaceholder")}
              {...form.register("email")}
            />
            {form.formState.errors.email && (
              <p className="text-sm text-destructive">{t("validation.email")}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="password">{t("auth.password")}</Label>
            <Input
              id="password"
              type="password"
              autoComplete="current-password"
              placeholder={t("auth.passwordPlaceholder")}
              {...form.register("password")}
            />
            {form.formState.errors.password && (
              <p className="text-sm text-destructive">{t("validation.minPassword")}</p>
            )}
          </div>

          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <Checkbox
                id="remember"
                checked={form.watch("remember")}
                onCheckedChange={(v) => form.setValue("remember", Boolean(v))}
              />
              <Label htmlFor="remember" className="cursor-pointer">
                {t("auth.rememberMe")}
              </Label>
            </div>
            <Link className={buttonVariants({variant: "link", className: "px-0"})} href={`/${locale}/forgot-password`}>
              {t("auth.forgotPassword")}
            </Link>
          </div>

          <Button type="submit" className="w-full" disabled={login.isPending}>
            {login.isPending ? t("common.loading") : t("auth.signIn")}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginForm />
    </Suspense>
  );
}
