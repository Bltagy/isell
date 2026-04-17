"use client";

import React from "react";
import {useDropzone} from "react-dropzone";
import {Upload, X, Loader2, GripVertical} from "lucide-react";
import {cn} from "@/lib/utils";
import {Button} from "@/components/ui/button";
import Image from "next/image";

type ImageGalleryUploaderProps = {
  images: string[];
  onChange: (images: string[]) => void;
  onUpload: (file: File) => Promise<string>;
  maxImages?: number;
};

export function ImageGalleryUploader({
  images,
  onChange,
  onUpload,
  maxImages = 5,
}: ImageGalleryUploaderProps) {
  const [uploading, setUploading] = React.useState(false);

  const {getRootProps, getInputProps, isDragActive} = useDropzone({
    accept: {"image/*": []},
    maxSize: 5 * 1024 * 1024,
    multiple: true,
    disabled: images.length >= maxImages || uploading,
    onDrop: async (accepted) => {
      setUploading(true);
      try {
        const urls = await Promise.all(accepted.slice(0, maxImages - images.length).map(onUpload));
        onChange([...images, ...urls]);
      } catch {
        // ignore
      } finally {
        setUploading(false);
      }
    },
  });

  const remove = (index: number) => {
    onChange(images.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-3">
        {images.map((url, i) => (
          <div key={url} className="relative group">
            <div className="relative h-20 w-20 rounded-md overflow-hidden border">
              <Image src={url} alt={`Gallery ${i + 1}`} fill className="object-cover" />
            </div>
            <Button
              type="button"
              variant="destructive"
              size="icon"
              className="absolute -top-2 -end-2 h-5 w-5 opacity-0 group-hover:opacity-100 transition-opacity"
              onClick={() => remove(i)}
              aria-label="Remove image"
            >
              <X className="h-3 w-3" />
            </Button>
            <div className="absolute bottom-1 start-1 cursor-grab opacity-0 group-hover:opacity-100 transition-opacity">
              <GripVertical className="h-3 w-3 text-white drop-shadow" />
            </div>
          </div>
        ))}

        {images.length < maxImages && (
          <div
            {...getRootProps()}
            className={cn(
              "flex h-20 w-20 flex-col items-center justify-center rounded-md border-2 border-dashed cursor-pointer transition-colors",
              isDragActive ? "border-primary bg-primary/5" : "border-border hover:border-primary/50",
              uploading && "pointer-events-none opacity-60"
            )}
          >
            <input {...getInputProps()} />
            {uploading ? (
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            ) : (
              <Upload className="h-5 w-5 text-muted-foreground" />
            )}
            <span className="text-[10px] text-muted-foreground mt-1">Add</span>
          </div>
        )}
      </div>
      <p className="text-xs text-muted-foreground">
        {images.length}/{maxImages} images. Drag to reorder.
      </p>
    </div>
  );
}
