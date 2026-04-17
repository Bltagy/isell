"use client";

import Image from "next/image";

type PhoneMockupProps = {
  appName: string;
  primaryColor: string;
  backgroundColor: string;
  textColor: string;
  fontFamily: string;
  logoUrl?: string;
  maintenanceMode?: boolean;
};

export function PhoneMockup({appName, primaryColor, backgroundColor, textColor, fontFamily, logoUrl, maintenanceMode}: PhoneMockupProps) {
  return (
    <div className="flex justify-center">
      <div className="relative w-56 h-[460px] rounded-[2.5rem] border-4 border-gray-800 bg-gray-800 shadow-2xl overflow-hidden">
        {/* Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-5 bg-gray-800 rounded-b-xl z-10" />

        {/* Screen */}
        <div
          className="absolute inset-1 rounded-[2rem] overflow-hidden flex flex-col"
          style={{backgroundColor, color: textColor, fontFamily}}
        >
          {maintenanceMode ? (
            <div className="flex flex-1 flex-col items-center justify-center p-4 text-center">
              <div className="text-3xl mb-3">🔧</div>
              <p className="font-semibold text-sm">Under Maintenance</p>
              <p className="text-xs opacity-70 mt-1">We'll be back soon!</p>
            </div>
          ) : (
            <>
              {/* Status bar */}
              <div className="flex justify-between px-4 pt-6 pb-1 text-[9px] opacity-60">
                <span>9:41</span>
                <span>●●●</span>
              </div>

              {/* Header */}
              <div className="flex items-center gap-2 px-4 py-2" style={{backgroundColor: primaryColor}}>
                {logoUrl ? (
                  <div className="relative h-6 w-6 rounded overflow-hidden">
                    <Image src={logoUrl} alt="Logo" fill className="object-cover" />
                  </div>
                ) : (
                  <div className="h-6 w-6 rounded bg-white/30" />
                )}
                <span className="text-white text-xs font-semibold truncate">{appName || "App Name"}</span>
              </div>

              {/* Content */}
              <div className="flex-1 p-3 space-y-2">
                {/* Banner placeholder */}
                <div className="h-16 rounded-lg" style={{backgroundColor: primaryColor + "33"}} />

                {/* Category pills */}
                <div className="flex gap-1 overflow-hidden">
                  {["All", "Pizza", "Burgers"].map((cat) => (
                    <div key={cat} className="rounded-full px-2 py-0.5 text-[8px] text-white shrink-0" style={{backgroundColor: primaryColor}}>
                      {cat}
                    </div>
                  ))}
                </div>

                {/* Product cards */}
                {[1, 2].map((i) => (
                  <div key={i} className="flex gap-2 rounded-lg border p-2" style={{borderColor: primaryColor + "44"}}>
                    <div className="h-10 w-10 rounded bg-muted shrink-0" />
                    <div className="flex-1 space-y-1">
                      <div className="h-2 w-16 rounded bg-current opacity-30" />
                      <div className="h-2 w-10 rounded bg-current opacity-20" />
                      <div className="h-2 w-8 rounded" style={{backgroundColor: primaryColor}} />
                    </div>
                  </div>
                ))}
              </div>

              {/* Bottom nav */}
              <div className="flex justify-around py-2 border-t" style={{borderColor: primaryColor + "33"}}>
                {["🏠", "🔍", "🛒", "👤"].map((icon) => (
                  <span key={icon} className="text-sm">{icon}</span>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
