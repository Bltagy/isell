"use client";

import React from "react";
import {Tabs, TabsContent, TabsList, TabsTrigger} from "@/components/ui/tabs";
import {Input} from "@/components/ui/input";
import {Textarea} from "@/components/ui/textarea";
import {Label} from "@/components/ui/label";

type BilingualInputProps = {
  labelEn?: string;
  labelAr?: string;
  valueEn: string;
  valueAr: string;
  onChangeEn: (v: string) => void;
  onChangeAr: (v: string) => void;
  multiline?: boolean;
  rows?: number;
  placeholderEn?: string;
  placeholderAr?: string;
  errorEn?: string;
  errorAr?: string;
  required?: boolean;
};

export function BilingualInput({
  labelEn = "English",
  labelAr = "العربية",
  valueEn,
  valueAr,
  onChangeEn,
  onChangeAr,
  multiline = false,
  rows = 3,
  placeholderEn,
  placeholderAr,
  errorEn,
  errorAr,
  required,
}: BilingualInputProps) {
  const Component = multiline ? Textarea : Input;

  return (
    <Tabs defaultValue="en">
      <TabsList className="mb-2">
        <TabsTrigger value="en">{labelEn}</TabsTrigger>
        <TabsTrigger value="ar">{labelAr}</TabsTrigger>
      </TabsList>

      <TabsContent value="en">
        <Component
          dir="ltr"
          value={valueEn}
          onChange={(e) => onChangeEn(e.target.value)}
          placeholder={placeholderEn}
          required={required}
          rows={multiline ? rows : undefined}
          className={errorEn ? "border-destructive" : ""}
        />
        {errorEn && <p className="mt-1 text-sm text-destructive">{errorEn}</p>}
      </TabsContent>

      <TabsContent value="ar">
        <Component
          dir="rtl"
          value={valueAr}
          onChange={(e) => onChangeAr(e.target.value)}
          placeholder={placeholderAr}
          required={required}
          rows={multiline ? rows : undefined}
          className={errorAr ? "border-destructive" : ""}
        />
        {errorAr && <p className="mt-1 text-sm text-destructive">{errorAr}</p>}
      </TabsContent>
    </Tabs>
  );
}
