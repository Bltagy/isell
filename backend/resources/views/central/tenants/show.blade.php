@extends('central.layouts.app')

@section('title', $tenant->name)
@section('page-title', $tenant->name)
@section('page-subtitle', 'Tenant details & full management')

@section('content')

{{-- ── Breadcrumb ───────────────────────────────────────────── --}}
<div class="flex items-center gap-2 text-xs text-slate-500 mb-5">
    <a href="{{ route('central.tenants') }}" class="hover:text-sky-600 transition-colors">Tenants</a>
    <i class="fa-solid fa-chevron-right text-[10px]"></i>
    <span class="text-slate-700 font-medium">{{ $tenant->name }}</span>
</div>

<div class="grid grid-cols-1 xl:grid-cols-3 gap-6">

{{-- ════════════════════════════════════════════════════════════
     LEFT COLUMN
═════════════════════════════════════════════════════════════ --}}
<div class="xl:col-span-2 space-y-6">

    {{-- ── 1. Edit Tenant Info ─────────────────────────────── --}}
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <div class="flex items-center gap-2">
                <i class="fa-solid fa-building text-slate-400"></i>
                <h3 class="font-semibold text-slate-800">Tenant Information</h3>
            </div>
            @include('central.partials.status-badge', ['status' => $tenant->trashed() ? 'deleted' : $tenant->status])
        </div>

        @unless($tenant->trashed())
        <form method="POST" action="{{ route('central.tenants.update', $tenant->id) }}" class="px-6 py-5">
            @csrf @method('PUT')
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Tenant ID</label>
                    <p class="font-mono text-sm text-slate-600 bg-slate-50 px-3 py-2.5 rounded-xl border border-slate-200 select-all">{{ $tenant->id }}</p>
                </div>
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Status</label>
                    <select name="status"
                            class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                        <option value="active"    {{ $tenant->status === 'active'    ? 'selected' : '' }}>Active</option>
                        <option value="suspended" {{ $tenant->status === 'suspended' ? 'selected' : '' }}>Suspended</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Business Name <span class="text-red-500">*</span></label>
                    <input type="text" name="name" value="{{ old('name', $tenant->name) }}" required
                           class="w-full px-3 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 @error('name') border-red-400 @enderror">
                    @error('name')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Admin Email <span class="text-red-500">*</span></label>
                    <input type="email" name="email" value="{{ old('email', $tenant->email) }}" required
                           class="w-full px-3 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 @error('email') border-red-400 @enderror">
                    @error('email')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <div class="sm:col-span-2 flex items-center justify-between pt-1">
                    <p class="text-xs text-slate-400">Created {{ $tenant->created_at?->format('d M Y, H:i') }}</p>
                    <button type="submit"
                            class="inline-flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-5 py-2 rounded-xl transition-colors shadow-sm">
                        <i class="fa-solid fa-floppy-disk"></i> Save Changes
                    </button>
                </div>
            </div>
        </form>
        @else
        <div class="px-6 py-5 grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
            <div><p class="text-xs text-slate-500 mb-1">ID</p><p class="font-mono text-slate-700">{{ $tenant->id }}</p></div>
            <div><p class="text-xs text-slate-500 mb-1">Name</p><p class="text-slate-700">{{ $tenant->name }}</p></div>
            <div><p class="text-xs text-slate-500 mb-1">Email</p><p class="text-slate-700">{{ $tenant->email }}</p></div>
            <div><p class="text-xs text-slate-500 mb-1">Deleted</p><p class="text-slate-700">{{ $tenant->deleted_at?->format('d M Y, H:i') }}</p></div>
        </div>
        @endunless

        {{-- Danger actions --}}
        @unless($tenant->trashed())
        <div class="px-6 py-4 bg-slate-50 border-t border-slate-100 flex flex-wrap gap-2">
            <form method="POST" action="{{ route('central.tenants.destroy', $tenant->id) }}"
                  onsubmit="return confirm('Permanently delete {{ addslashes($tenant->name) }}? This cannot be undone.')">
                @csrf @method('DELETE')
                <button class="inline-flex items-center gap-2 text-sm text-red-600 bg-red-50 hover:bg-red-100 px-4 py-2 rounded-xl transition-colors font-medium">
                    <i class="fa-solid fa-trash"></i> Delete Tenant
                </button>
            </form>
        </div>
        @endunless
    </div>

    {{-- ── 2. Domain Management ────────────────────────────── --}}
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <div class="flex items-center gap-2">
                <i class="fa-solid fa-globe text-slate-400"></i>
                <h3 class="font-semibold text-slate-800">Domains</h3>
                <span class="text-xs text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">{{ $tenant->domains->count() }}</span>
            </div>
            @unless($tenant->trashed())
            <button onclick="togglePanel('panel-add-domain')"
                    class="inline-flex items-center gap-1.5 text-xs text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 px-3 py-1.5 rounded-lg transition-colors font-medium">
                <i class="fa-solid fa-plus"></i> Add Domain
            </button>
            @endunless
        </div>

        {{-- Add domain form (hidden by default) --}}
        @unless($tenant->trashed())
        <div id="panel-add-domain" class="hidden border-b border-slate-100 bg-sky-50/50 px-6 py-4">
            <form method="POST" action="{{ route('central.tenants.domains.store', $tenant->id) }}"
                  class="flex flex-wrap items-end gap-3">
                @csrf
                <div class="flex-1 min-w-48">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Domain / Subdomain</label>
                    <input type="text" name="domain" placeholder="e.g. mystore.yourdomain.com" required
                           class="w-full px-3 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                </div>
                <div class="flex items-center gap-2 pb-0.5">
                    <input type="checkbox" name="is_primary" id="new_primary" value="1"
                           class="rounded border-slate-300 text-sky-500 focus:ring-sky-500">
                    <label for="new_primary" class="text-sm text-slate-700 whitespace-nowrap">Set as primary</label>
                </div>
                <button type="submit"
                        class="inline-flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-4 py-2.5 rounded-xl transition-colors">
                    <i class="fa-solid fa-plus"></i> Add
                </button>
            </form>
        </div>
        @endunless

        {{-- Domain list --}}
        <div class="divide-y divide-slate-100">
            @forelse($tenant->domains as $domain)
            <div class="px-6 py-4" id="domain-row-{{ $domain->id }}">
                {{-- View mode --}}
                <div class="flex items-center justify-between gap-3" id="domain-view-{{ $domain->id }}">
                    <div class="flex items-center gap-3 min-w-0">
                        <div class="w-9 h-9 rounded-xl {{ $domain->is_primary ? 'bg-sky-100' : 'bg-slate-100' }} flex items-center justify-center flex-shrink-0">
                            <i class="fa-solid fa-globe {{ $domain->is_primary ? 'text-sky-500' : 'text-slate-400' }} text-sm"></i>
                        </div>
                        <div class="min-w-0">
                            <p class="text-sm font-medium text-slate-800 truncate">{{ $domain->domain }}</p>
                            <div class="flex items-center gap-2 mt-0.5">
                                @if($domain->is_primary)
                                    <span class="text-xs text-sky-600 font-medium bg-sky-50 px-1.5 py-0.5 rounded">Primary</span>
                                @endif
                                <a href="http://{{ $domain->domain }}" target="_blank"
                                   class="text-xs text-slate-400 hover:text-sky-600 transition-colors">
                                    Visit <i class="fa-solid fa-arrow-up-right-from-square text-[9px]"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                    @unless($tenant->trashed())
                    <div class="flex items-center gap-1.5 flex-shrink-0">
                        @unless($domain->is_primary)
                        <form method="POST" action="{{ route('central.tenants.domains.primary', [$tenant->id, $domain->id]) }}">
                            @csrf
                            <button type="submit" title="Set as primary"
                                    class="text-xs text-slate-500 hover:text-sky-600 bg-slate-100 hover:bg-sky-50 px-2.5 py-1.5 rounded-lg transition-colors">
                                <i class="fa-solid fa-star"></i>
                            </button>
                        </form>
                        @endunless
                        <button onclick="toggleDomainEdit({{ $domain->id }})"
                                class="text-xs text-slate-500 hover:text-slate-700 bg-slate-100 hover:bg-slate-200 px-2.5 py-1.5 rounded-lg transition-colors">
                            <i class="fa-solid fa-pen"></i>
                        </button>
                        @unless($domain->is_primary)
                        <form method="POST" action="{{ route('central.tenants.domains.destroy', [$tenant->id, $domain->id]) }}"
                              onsubmit="return confirm('Remove domain {{ addslashes($domain->domain) }}?')">
                            @csrf @method('DELETE')
                            <button type="submit"
                                    class="text-xs text-red-500 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                <i class="fa-solid fa-trash"></i>
                            </button>
                        </form>
                        @endunless
                    </div>
                    @endunless
                </div>

                {{-- Edit mode (hidden) --}}
                <div id="domain-edit-{{ $domain->id }}" class="hidden mt-3">
                    <form method="POST" action="{{ route('central.tenants.domains.update', [$tenant->id, $domain->id]) }}"
                          class="flex flex-wrap items-end gap-3 bg-slate-50 rounded-xl p-4">
                        @csrf @method('PUT')
                        <div class="flex-1 min-w-48">
                            <label class="block text-xs font-medium text-slate-700 mb-1.5">Domain</label>
                            <input type="text" name="domain" value="{{ $domain->domain }}" required
                                   class="w-full px-3 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                        </div>
                        <div class="flex items-center gap-2 pb-0.5">
                            <input type="checkbox" name="is_primary" id="edit_primary_{{ $domain->id }}" value="1"
                                   {{ $domain->is_primary ? 'checked' : '' }}
                                   class="rounded border-slate-300 text-sky-500 focus:ring-sky-500">
                            <label for="edit_primary_{{ $domain->id }}" class="text-sm text-slate-700 whitespace-nowrap">Primary</label>
                        </div>
                        <div class="flex gap-2">
                            <button type="submit"
                                    class="inline-flex items-center gap-1.5 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-4 py-2.5 rounded-xl transition-colors">
                                <i class="fa-solid fa-floppy-disk"></i> Save
                            </button>
                            <button type="button" onclick="toggleDomainEdit({{ $domain->id }})"
                                    class="px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-200 rounded-xl transition-colors">
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            </div>
            @empty
            <div class="px-6 py-10 text-center">
                <i class="fa-solid fa-globe text-slate-300 text-2xl mb-2 block"></i>
                <p class="text-slate-400 text-sm">No domains configured.</p>
            </div>
            @endforelse
        </div>
    </div>

    {{-- ── 3. Subscription History ─────────────────────────── --}}
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center gap-2">
            <i class="fa-solid fa-receipt text-slate-400"></i>
            <h3 class="font-semibold text-slate-800">Subscription History</h3>
        </div>
        <div class="divide-y divide-slate-100">
            @forelse($tenant->subscriptions->sortByDesc('id') as $sub)
            <div class="px-6 py-4" id="sub-row-{{ $sub->id }}">
                {{-- View mode --}}
                <div id="sub-view-{{ $sub->id }}" class="flex items-center justify-between gap-3">
                    <div class="flex items-center gap-3 min-w-0">
                        <div class="w-9 h-9 rounded-xl {{ $sub->status === 'active' ? 'bg-emerald-100' : 'bg-slate-100' }} flex items-center justify-center flex-shrink-0">
                            <i class="fa-solid fa-layer-group {{ $sub->status === 'active' ? 'text-emerald-500' : 'text-slate-400' }} text-sm"></i>
                        </div>
                        <div>
                            <p class="text-sm font-medium text-slate-800">{{ $sub->plan?->name ?? 'Unknown Plan' }}</p>
                            <p class="text-xs text-slate-400 mt-0.5">
                                {{ $sub->start_date?->format('d M Y') }} → {{ $sub->end_date?->format('d M Y') }}
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center gap-2 flex-shrink-0">
                        @include('central.partials.status-badge', ['status' => $sub->status])
                        @unless($tenant->trashed())
                        <button onclick="toggleSubEdit({{ $sub->id }})"
                                class="text-xs text-slate-500 hover:text-slate-700 bg-slate-100 hover:bg-slate-200 px-2.5 py-1.5 rounded-lg transition-colors">
                            <i class="fa-solid fa-pen"></i>
                        </button>
                        <form method="POST" action="{{ route('central.tenants.subscriptions.destroy', [$tenant->id, $sub->id]) }}"
                              onsubmit="return confirm('Remove this subscription?')">
                            @csrf @method('DELETE')
                            <button type="submit"
                                    class="text-xs text-red-500 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                <i class="fa-solid fa-trash"></i>
                            </button>
                        </form>
                        @endunless
                    </div>
                </div>

                {{-- Edit mode (hidden) --}}
                <div id="sub-edit-{{ $sub->id }}" class="hidden mt-3">
                    <form method="POST" action="{{ route('central.tenants.subscriptions.update', [$tenant->id, $sub->id]) }}"
                          class="bg-slate-50 rounded-xl p-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
                        @csrf @method('PUT')
                        <div>
                            <label class="block text-xs font-medium text-slate-700 mb-1.5">Plan</label>
                            <select name="plan_id" required
                                    class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                                @foreach($plans as $plan)
                                <option value="{{ $plan->id }}" {{ $sub->plan_id == $plan->id ? 'selected' : '' }}>
                                    {{ $plan->name }}
                                </option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-medium text-slate-700 mb-1.5">Status</label>
                            <select name="status" required
                                    class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                                <option value="active"    {{ $sub->status === 'active'    ? 'selected' : '' }}>Active</option>
                                <option value="expired"   {{ $sub->status === 'expired'   ? 'selected' : '' }}>Expired</option>
                                <option value="cancelled" {{ $sub->status === 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-medium text-slate-700 mb-1.5">Start Date</label>
                            <input type="date" name="start_date" value="{{ $sub->start_date?->format('Y-m-d') }}" required
                                   class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                        </div>
                        <div>
                            <label class="block text-xs font-medium text-slate-700 mb-1.5">End Date</label>
                            <input type="date" name="end_date" value="{{ $sub->end_date?->format('Y-m-d') }}" required
                                   class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                        </div>
                        <div class="sm:col-span-2 flex gap-2">
                            <button type="submit"
                                    class="inline-flex items-center gap-1.5 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-4 py-2.5 rounded-xl transition-colors">
                                <i class="fa-solid fa-floppy-disk"></i> Save
                            </button>
                            <button type="button" onclick="toggleSubEdit({{ $sub->id }})"
                                    class="px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-200 rounded-xl transition-colors">
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            </div>
            @empty
            <div class="px-6 py-10 text-center">
                <i class="fa-solid fa-receipt text-slate-300 text-2xl mb-2 block"></i>
                <p class="text-slate-400 text-sm">No subscriptions yet.</p>
            </div>
            @endforelse
        </div>
    </div>

</div>{{-- end left column --}}

{{-- ════════════════════════════════════════════════════════════
     RIGHT COLUMN
═════════════════════════════════════════════════════════════ --}}
<div class="space-y-6">

    {{-- ── Quick Stats ─────────────────────────────────────── --}}
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 p-6">
        <h3 class="font-semibold text-slate-800 mb-4">Overview</h3>
        @php
            $activeSub = $tenant->subscriptions->firstWhere('status', 'active');
            $daysLeft  = $activeSub?->end_date ? now()->diffInDays($activeSub->end_date, false) : null;
        @endphp
        <div class="space-y-3">
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Status</span>
                @include('central.partials.status-badge', ['status' => $tenant->trashed() ? 'deleted' : $tenant->status])
            </div>
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Active plan</span>
                <span class="font-semibold text-slate-800">{{ $activeSub?->plan?->name ?? '—' }}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Expires</span>
                <span class="font-semibold {{ $daysLeft !== null && $daysLeft < 7 ? 'text-red-600' : 'text-slate-800' }}">
                    {{ $activeSub?->end_date?->format('d M Y') ?? '—' }}
                </span>
            </div>
            @if($daysLeft !== null)
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Days remaining</span>
                <span class="font-semibold {{ $daysLeft < 7 ? 'text-red-600' : ($daysLeft < 30 ? 'text-amber-600' : 'text-emerald-600') }}">
                    {{ $daysLeft > 0 ? $daysLeft : 'Expired' }}
                </span>
            </div>
            @endif
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Total subscriptions</span>
                <span class="font-semibold text-slate-800">{{ $tenant->subscriptions->count() }}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Domains</span>
                <span class="font-semibold text-slate-800">{{ $tenant->domains->count() }}</span>
            </div>
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500">Created</span>
                <span class="font-semibold text-slate-800">{{ $tenant->created_at?->format('d M Y') }}</span>
            </div>
        </div>
    </div>

    {{-- ── Assign New Subscription ─────────────────────────── --}}
    @unless($tenant->trashed())
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center gap-2">
            <i class="fa-solid fa-plus-circle text-slate-400"></i>
            <h3 class="font-semibold text-slate-800">Add Subscription</h3>
        </div>
        <form method="POST" action="{{ route('central.tenants.assign-plan', $tenant->id) }}" class="px-6 py-5 space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Plan</label>
                <select name="plan_id" required
                        class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500 bg-white">
                    <option value="">Select a plan…</option>
                    @foreach($plans as $plan)
                    <option value="{{ $plan->id }}">
                        {{ $plan->name }} — {{ number_format($plan->price_monthly / 100, 2) }} EGP/mo
                    </option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Start Date</label>
                <input type="date" name="start_date" value="{{ now()->format('Y-m-d') }}" required
                       class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500">
            </div>
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">End Date</label>
                <input type="date" name="end_date" value="{{ now()->addMonth()->format('Y-m-d') }}" required
                       class="w-full border border-slate-300 rounded-xl text-sm px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-sky-500">
            </div>
            <p class="text-xs text-slate-400">Any current active subscription will be cancelled.</p>
            <button type="submit"
                    class="w-full bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium py-2.5 rounded-xl transition-colors shadow-sm">
                Assign Plan
            </button>
        </form>
    </div>
    @endunless

</div>{{-- end right column --}}

</div>{{-- end grid --}}

@endsection

@push('scripts')
<script>
function togglePanel(id) {
    document.getElementById(id).classList.toggle('hidden');
}
function toggleDomainEdit(id) {
    document.getElementById('domain-view-' + id).classList.toggle('hidden');
    document.getElementById('domain-edit-' + id).classList.toggle('hidden');
}
function toggleSubEdit(id) {
    document.getElementById('sub-view-' + id).classList.toggle('hidden');
    document.getElementById('sub-edit-' + id).classList.toggle('hidden');
}

// Auto-open edit panels if there were validation errors
@if($errors->any())
    // Re-open the section that had errors based on old input
    @if(old('name') || old('email'))
        // info form — always visible
    @endif
@endif
</script>
@endpush
