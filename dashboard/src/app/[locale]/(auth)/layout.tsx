import {LanguageSwitcher} from "@/components/layout/LanguageSwitcher";

export default function AuthLayout({children}: {children: React.ReactNode}) {
  return (
    <div className="min-h-screen flex flex-col">
      <div className="flex items-center justify-end p-4">
        <LanguageSwitcher />
      </div>
      <div className="flex flex-1 items-center justify-center p-4">{children}</div>
    </div>
  );
}

