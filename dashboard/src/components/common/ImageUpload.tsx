"use client";

import React from "react";
import {useDropzone} from "react-dropzone";
import {Upload, X, Loader2} from "lucide-react";
import {cn} from "@/lib/utils";
import {Button} from "@/components/ui/button";
import Image from "next/image";

type ImageUploadProps = {
  value?: string;
  onChange: (url: string | null) => void;
  onUpload: (file: File) => Promise<string>;
  accept?: string[];
  maxSize?: number;
  className?: string;
  label?: string;
};

export function ImageUpload({
  value,
  onChange,
  onUpload,
  accept = ["image/jpeg", "image/png", "image/webp"],
  maxSize = 5 * 1024 * 1024,
  className,
  label = "Drop image here or click to upload",
}: ImageUploadProps) {
  const [uploading, setUploading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const {getRootProps, getInputProps, isDragActive} = useDropzone({
    accept: accept.reduce((acc, type) => ({...acc, [type]: []}), {}),
    maxSize,
    multiple: false,
    onDrop: async (accepted) => {
      if (!accepted[0]) return;
      setError(null);
      setUploading(true);
      try {
        const url = await onUpload(accepted[0]);
        onChange(url);
      } catch {
        setError("Upload failed. Please try again.");
      } finally {
        setUploading(false);
      }
    },
    onDropRejected: () => {
      setError("File rejected. Check size and format.");
    },
  });

  if (value) {
    return (
      <div className={cn("relative inline-block", className)}>
        <div className="relative h-32 w-32 rounded-md overflow-hidden border">
          <Image src={value} alt="Uploaded" fill className="object-cover" />
        </div>
        <Button
          type="button"
          variant="destructive"
          size="icon"
          className="absolute -top-2 -end-2 h-6 w-6"
          onClick={() => onChange(null)}
          aria-label="Remove image"
        >
          <X className="h-3 w-3" />
        </Button>
      </div>
    );
  }

  return (
    <div className={className}>
      <div
        {...getRootProps()}
        className={cn(
          "flex flex-col items-center justify-center rounded-md border-2 border-dashed p-6 cursor-pointer transition-colors",
          isDragActive ? "border-primary bg-primary/5" : "border-border hover:border-primary/50",
          uploading && "pointer-events-none opacity-60"
        )}
      >
        <input {...getInputProps()} />
        {uploading ? (
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        ) : (
          <Upload className="h-8 w-8 text-muted-foreground" />
        )}
        <p className="mt-2 text-sm text-muted-foreground text-center">{label}</p>
      </div>
      {error && <p className="mt-1 text-sm text-destructive">{error}</p>}
    </div>
  );
}
