@extends('central.layouts.app')

@section('title', 'Tenants')
@section('page-title', 'Tenants')
@section('page-subtitle', 'Manage all platform tenants')

@section('content')

{{-- ── Toolbar ──────────────────────────────────────────────── --}}
<div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-6">
    <form method="GET" action="{{ route('central.tenants') }}" class="flex flex-1 gap-2">
        <div class="relative flex-1 max-w-sm">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400">
                <i class="fa-solid fa-magnifying-glass text-sm"></i>
            </span>
            <input type="text" name="search" value="{{ request('search') }}"
                   placeholder="Search by name, email or ID…"
                   class="w-full pl-9 pr-4 py-2 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
        </div>
        <select name="status" onchange="this.form.submit()"
                class="border border-slate-300 rounded-xl text-sm px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-sky-500">
            <option value="">All statuses</option>
            <option value="active"    {{ request('status') === 'active'    ? 'selected' : '' }}>Active</option>
            <option value="suspended" {{ request('status') === 'suspended' ? 'selected' : '' }}>Suspended</option>
            <option value="deleted"   {{ request('status') === 'deleted'   ? 'selected' : '' }}>Deleted</option>
        </select>
    </form>

    <a href="{{ route('central.tenants.create') }}"
       class="inline-flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors shadow-sm whitespace-nowrap">
        <i class="fa-solid fa-plus"></i> New Tenant
    </a>
</div>

{{-- ── Table ────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-slate-50 text-left">
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Tenant</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Domain</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Subscription</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Created</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($tenants as $tenant)
                <tr class="hover:bg-slate-50 transition-colors">
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-3">
                            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-slate-700 to-slate-500 flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                                {{ strtoupper(substr($tenant->name, 0, 1)) }}
                            </div>
                            <div>
                                <p class="font-medium text-slate-800">{{ $tenant->name }}</p>
                                <p class="text-xs text-slate-400">{{ $tenant->email }}</p>
                                <p class="text-xs text-slate-300 font-mono">{{ $tenant->id }}</p>
                            </div>
                        </div>
                    </td>
                    <td class="px-6 py-4">
                        @if($tenant->primaryDomain)
                            <a href="http://{{ $tenant->primaryDomain->domain }}" target="_blank"
                               class="text-sky-600 hover:underline text-xs">
                                {{ $tenant->primaryDomain->domain }}
                                <i class="fa-solid fa-arrow-up-right-from-square text-[10px] ml-0.5"></i>
                            </a>
                        @else
                            <span class="text-slate-400 text-xs">—</span>
                        @endif
                    </td>
                    <td class="px-6 py-4">
                        @if($tenant->activeSubscription)
                            <div>
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-sky-100 text-sky-700">
                                    {{ $tenant->activeSubscription->plan?->name ?? 'Unknown' }}
                                </span>
                                <p class="text-xs text-slate-400 mt-0.5">
                                    Expires {{ $tenant->activeSubscription->end_date?->format('d M Y') }}
                                </p>
                            </div>
                        @else
                            <span class="text-slate-400 text-xs">No active plan</span>
                        @endif
                    </td>
                    <td class="px-6 py-4">
                        @include('central.partials.status-badge', ['status' => $tenant->trashed() ? 'deleted' : $tenant->status])
                    </td>
                    <td class="px-6 py-4 text-slate-500 text-xs">
                        {{ $tenant->created_at?->format('d M Y') }}
                    </td>
                    <td class="px-6 py-4">
                        <div class="flex items-center justify-end gap-2">
                            @unless($tenant->trashed())
                                <a href="{{ route('central.tenants.show', $tenant->id) }}"
                                   class="inline-flex items-center gap-1 text-xs text-slate-600 hover:text-sky-600 bg-slate-100 hover:bg-sky-50 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i class="fa-solid fa-eye"></i> View
                                </a>

                                @if($tenant->status === 'active')
                                <form method="POST" action="{{ route('central.tenants.suspend', $tenant->id) }}"
                                      onsubmit="return confirm('Suspend {{ addslashes($tenant->name) }}?')">
                                    @csrf
                                    <button class="inline-flex items-center gap-1 text-xs text-amber-700 hover:text-amber-800 bg-amber-50 hover:bg-amber-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                        <i class="fa-solid fa-ban"></i> Suspend
                                    </button>
                                </form>
                                @else
                                <form method="POST" action="{{ route('central.tenants.activate', $tenant->id) }}">
                                    @csrf
                                    <button class="inline-flex items-center gap-1 text-xs text-emerald-700 hover:text-emerald-800 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                        <i class="fa-solid fa-circle-check"></i> Activate
                                    </button>
                                </form>
                                @endif

                                <form method="POST" action="{{ route('central.tenants.destroy', $tenant->id) }}"
                                      onsubmit="return confirm('Delete {{ addslashes($tenant->name) }}? This cannot be undone.')">
                                    @csrf @method('DELETE')
                                    <button class="inline-flex items-center gap-1 text-xs text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </form>
                            @else
                                <span class="text-xs text-slate-400 italic">Deleted {{ $tenant->deleted_at?->diffForHumans() }}</span>
                            @endunless
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="px-6 py-16 text-center">
                        <i class="fa-solid fa-building text-slate-300 text-3xl mb-3 block"></i>
                        <p class="text-slate-500 font-medium">No tenants found</p>
                        <p class="text-slate-400 text-xs mt-1">Try adjusting your search or filters.</p>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Pagination --}}
    @if($tenants->hasPages())
    <div class="px-6 py-4 border-t border-slate-100 flex items-center justify-between">
        <p class="text-xs text-slate-500">
            Showing {{ $tenants->firstItem() }}–{{ $tenants->lastItem() }} of {{ $tenants->total() }} tenants
        </p>
        <div class="flex items-center gap-1">
            @if($tenants->onFirstPage())
                <span class="px-3 py-1.5 text-xs text-slate-400 bg-slate-50 rounded-lg cursor-not-allowed">← Prev</span>
            @else
                <a href="{{ $tenants->previousPageUrl() }}" class="px-3 py-1.5 text-xs text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">← Prev</a>
            @endif

            @if($tenants->hasMorePages())
                <a href="{{ $tenants->nextPageUrl() }}" class="px-3 py-1.5 text-xs text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">Next →</a>
            @else
                <span class="px-3 py-1.5 text-xs text-slate-400 bg-slate-50 rounded-lg cursor-not-allowed">Next →</span>
            @endif
        </div>
    </div>
    @endif
</div>

@endsection
