"use client";

import React from "react";
import {HexColorPicker} from "react-colorful";
import {Popover, PopoverContent, PopoverTrigger} from "@/components/ui/popover";
import {Input} from "@/components/ui/input";
import {Label} from "@/components/ui/label";

type ColorPickerFieldProps = {
  label: string;
  value: string;
  onChange: (color: string) => void;
};

export function ColorPickerField({label, value, onChange}: ColorPickerFieldProps) {
  return (
    <div className="flex items-center gap-3">
      <Popover>
        <PopoverTrigger
          type="button"
          className="h-8 w-8 rounded border border-border shadow-sm shrink-0"
          style={{backgroundColor: value}}
          aria-label={`Pick ${label} color`}
        />
        <PopoverContent className="w-auto p-3" align="start">
          <HexColorPicker color={value} onChange={onChange} />
        </PopoverContent>
      </Popover>
      <div className="flex-1">
        <Label className="text-xs text-muted-foreground">{label}</Label>
        <Input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-7 font-mono text-xs"
          maxLength={7}
        />
      </div>
    </div>
  );
}
