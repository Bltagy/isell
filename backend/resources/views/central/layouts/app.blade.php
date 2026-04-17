<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Central Admin') — Super Admin Panel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        brand: { 50:'#f0f9ff', 100:'#e0f2fe', 500:'#0ea5e9', 600:'#0284c7', 700:'#0369a1', 900:'#0c4a6e' }
                    }
                }
            }
        }
    </script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <style>
        [x-cloak] { display: none !important; }
        .sidebar-link { @apply flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-all duration-150; }
        .sidebar-link:hover { @apply bg-white/10 text-white; }
        .sidebar-link.active { @apply bg-white/20 text-white shadow-sm; }
        .sidebar-link:not(.active) { @apply text-slate-300; }
    </style>
    @stack('head')
</head>
<body class="h-full bg-slate-100 font-sans antialiased">

<div class="flex h-full min-h-screen">

    {{-- ── Sidebar ──────────────────────────────────────────── --}}
    <aside class="w-64 flex-shrink-0 bg-gradient-to-b from-slate-900 to-slate-800 flex flex-col shadow-xl">

        {{-- Logo --}}
        <div class="flex items-center gap-3 px-6 py-5 border-b border-white/10">
            <div class="w-9 h-9 rounded-xl bg-brand-500 flex items-center justify-center shadow">
                <i class="fa-solid fa-store text-white text-sm"></i>
            </div>
            <div>
                <p class="text-white font-bold text-sm leading-tight">Super Admin</p>
                <p class="text-slate-400 text-xs">Central Panel</p>
            </div>
        </div>

        {{-- Nav --}}
        <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
            <p class="px-4 text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Overview</p>

            <a href="{{ route('central.dashboard') }}"
               class="sidebar-link {{ request()->routeIs('central.dashboard') ? 'active' : '' }}">
                <i class="fa-solid fa-gauge-high w-4 text-center"></i> Dashboard
            </a>

            <p class="px-4 text-xs font-semibold text-slate-500 uppercase tracking-wider mt-4 mb-2">Management</p>

            <a href="{{ route('central.tenants') }}"
               class="sidebar-link {{ request()->routeIs('central.tenants*') ? 'active' : '' }}">
                <i class="fa-solid fa-building w-4 text-center"></i> Tenants
            </a>

            <a href="{{ route('central.plans') }}"
               class="sidebar-link {{ request()->routeIs('central.plans*') ? 'active' : '' }}">
                <i class="fa-solid fa-layer-group w-4 text-center"></i> Subscription Plans
            </a>
        </nav>

        {{-- User --}}
        <div class="px-4 py-4 border-t border-white/10">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full bg-brand-500 flex items-center justify-center text-white text-xs font-bold">
                    {{ strtoupper(substr(Auth::guard('central')->user()->name ?? 'A', 0, 1)) }}
                </div>
                <div class="flex-1 min-w-0">
                    <p class="text-white text-xs font-medium truncate">{{ Auth::guard('central')->user()->name ?? 'Admin' }}</p>
                    <p class="text-slate-400 text-xs truncate">{{ Auth::guard('central')->user()->email ?? '' }}</p>
                </div>
                <form method="POST" action="{{ route('central.logout') }}">
                    @csrf
                    <button type="submit" class="text-slate-400 hover:text-white transition-colors" title="Logout">
                        <i class="fa-solid fa-right-from-bracket text-sm"></i>
                    </button>
                </form>
            </div>
        </div>
    </aside>

    {{-- ── Main ─────────────────────────────────────────────── --}}
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">

        {{-- Top bar --}}
        <header class="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between shadow-sm">
            <div>
                <h1 class="text-lg font-semibold text-slate-800">@yield('page-title', 'Dashboard')</h1>
                <p class="text-xs text-slate-500 mt-0.5">@yield('page-subtitle', 'Central administration panel')</p>
            </div>
            <div class="flex items-center gap-3">
                <span class="text-xs text-slate-400">{{ now()->format('D, d M Y') }}</span>
                <div class="w-px h-5 bg-slate-200"></div>
                <span class="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span> Live
                </span>
            </div>
        </header>

        {{-- Flash messages --}}
        <div class="px-6 pt-4">
            @if(session('success'))
                <div class="flex items-center gap-3 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm px-4 py-3 rounded-xl mb-0" role="alert">
                    <i class="fa-solid fa-circle-check text-emerald-500"></i>
                    {{ session('success') }}
                </div>
            @endif
            @if(session('error'))
                <div class="flex items-start gap-3 bg-red-50 border border-red-200 text-red-800 text-sm px-4 py-3 rounded-xl mb-0" role="alert">
                    <i class="fa-solid fa-circle-exclamation text-red-500 mt-0.5"></i>
                    {{ session('error') }}
                </div>
            @endif
            @if($errors->any())
                <div class="flex items-start gap-3 bg-red-50 border border-red-200 text-red-800 text-sm px-4 py-3 rounded-xl mb-0" role="alert">
                    <i class="fa-solid fa-circle-exclamation text-red-500 mt-0.5"></i>
                    <ul class="list-disc list-inside space-y-0.5">
                        @foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach
                    </ul>
                </div>
            @endif
        </div>

        {{-- Content --}}
        <main class="flex-1 overflow-y-auto p-6">
            @yield('content')
        </main>
    </div>
</div>

@stack('scripts')
</body>
</html>
