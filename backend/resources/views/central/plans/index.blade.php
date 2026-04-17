@extends('central.layouts.app')

@section('title', 'Subscription Plans')
@section('page-title', 'Subscription Plans')
@section('page-subtitle', 'Manage pricing plans available to tenants')

@section('content')

{{-- ── Header ───────────────────────────────────────────────── --}}
<div class="flex items-center justify-between mb-6">
    <p class="text-sm text-slate-500">{{ $plans->count() }} plan(s) total</p>
    <button onclick="document.getElementById('modal-create').classList.remove('hidden')"
            class="inline-flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors shadow-sm">
        <i class="fa-solid fa-plus"></i> New Plan
    </button>
</div>

{{-- ── Plans Grid ───────────────────────────────────────────── --}}
<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
    @forelse($plans as $plan)
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex flex-col {{ $plan->trashed() ? 'opacity-60' : '' }}">
        <div class="px-6 pt-6 pb-4 border-b border-slate-100">
            <div class="flex items-start justify-between gap-2">
                <div>
                    <h3 class="font-bold text-slate-800 text-lg">{{ $plan->name }}</h3>
                    <div class="flex items-baseline gap-1 mt-1">
                        <span class="text-2xl font-bold text-sky-600">{{ number_format($plan->price_monthly / 100, 0) }}</span>
                        <span class="text-slate-500 text-sm">EGP/mo</span>
                    </div>
                    <p class="text-xs text-slate-400 mt-0.5">{{ number_format($plan->price_yearly / 100, 0) }} EGP/yr</p>
                </div>
                <div class="flex flex-col items-end gap-1.5">
                    @if($plan->trashed())
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">Deleted</span>
                    @elseif($plan->is_active)
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">Active</span>
                    @else
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600">Inactive</span>
                    @endif
                    <span class="text-xs text-slate-500 font-medium">{{ $plan->active_count }} subscribers</span>
                </div>
            </div>
        </div>

        <div class="px-6 py-4 flex-1 space-y-2">
            @php
                $limits = [
                    ['icon' => 'fa-box', 'label' => 'Products', 'value' => number_format($plan->max_products)],
                    ['icon' => 'fa-receipt', 'label' => 'Orders/mo', 'value' => number_format($plan->max_orders_per_month)],
                    ['icon' => 'fa-code-branch', 'label' => 'Branches', 'value' => number_format($plan->max_branches)],
                ];
            @endphp
            @foreach($limits as $limit)
            <div class="flex items-center justify-between text-sm">
                <span class="flex items-center gap-2 text-slate-500">
                    <i class="fa-solid {{ $limit['icon'] }} w-4 text-center text-slate-400"></i>
                    {{ $limit['label'] }}
                </span>
                <span class="font-semibold text-slate-800">{{ $limit['value'] }}</span>
            </div>
            @endforeach

            @if($plan->features_json)
            <div class="pt-2 border-t border-slate-100">
                <p class="text-xs text-slate-500 mb-1.5">Features</p>
                <div class="flex flex-wrap gap-1">
                    @foreach((array)$plan->features_json as $feature)
                    <span class="text-xs bg-sky-50 text-sky-700 px-2 py-0.5 rounded-full">{{ $feature }}</span>
                    @endforeach
                </div>
            </div>
            @endif
        </div>

        @unless($plan->trashed())
        <div class="px-6 py-4 bg-slate-50 border-t border-slate-100 flex gap-2">
            <button onclick="openEditModal({{ $plan->id }}, {{ json_encode($plan) }})"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 text-xs text-slate-700 bg-white border border-slate-200 hover:bg-slate-100 px-3 py-2 rounded-xl transition-colors font-medium">
                <i class="fa-solid fa-pen"></i> Edit
            </button>
            <form method="POST" action="{{ route('central.plans.destroy', $plan->id) }}"
                  onsubmit="return confirm('Delete plan {{ addslashes($plan->name) }}?')">
                @csrf @method('DELETE')
                <button class="inline-flex items-center justify-center gap-1.5 text-xs text-red-600 bg-red-50 hover:bg-red-100 px-3 py-2 rounded-xl transition-colors font-medium">
                    <i class="fa-solid fa-trash"></i>
                </button>
            </form>
        </div>
        @endunless
    </div>
    @empty
    <div class="col-span-3 bg-white rounded-2xl shadow-sm border border-slate-100 py-16 text-center">
        <i class="fa-solid fa-layer-group text-slate-300 text-3xl mb-3 block"></i>
        <p class="text-slate-500 font-medium">No plans yet</p>
        <p class="text-slate-400 text-xs mt-1">Create your first subscription plan.</p>
    </div>
    @endforelse
</div>

{{-- ── Create Modal ─────────────────────────────────────────── --}}
<div id="modal-create" class="hidden fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between px-6 py-5 border-b border-slate-100">
            <h3 class="font-semibold text-slate-800">Create New Plan</h3>
            <button onclick="document.getElementById('modal-create').classList.add('hidden')"
                    class="text-slate-400 hover:text-slate-600 transition-colors">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>
        <form method="POST" action="{{ route('central.plans.store') }}" class="px-6 py-6 space-y-4">
            @csrf
            @include('central.plans._form')
            <div class="flex gap-3 pt-2">
                <button type="submit" class="flex-1 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium py-2.5 rounded-xl transition-colors">
                    Create Plan
                </button>
                <button type="button" onclick="document.getElementById('modal-create').classList.add('hidden')"
                        class="px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-100 rounded-xl transition-colors">
                    Cancel
                </button>
            </div>
        </form>
    </div>
</div>

{{-- ── Edit Modal ───────────────────────────────────────────── --}}
<div id="modal-edit" class="hidden fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between px-6 py-5 border-b border-slate-100">
            <h3 class="font-semibold text-slate-800">Edit Plan</h3>
            <button onclick="document.getElementById('modal-edit').classList.add('hidden')"
                    class="text-slate-400 hover:text-slate-600 transition-colors">
                <i class="fa-solid fa-xmark text-lg"></i>
            </button>
        </div>
        <form id="edit-form" method="POST" action="" class="px-6 py-6 space-y-4">
            @csrf @method('PUT')
            @include('central.plans._form', ['edit' => true])
            <div class="flex gap-3 pt-2">
                <button type="submit" class="flex-1 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium py-2.5 rounded-xl transition-colors">
                    Save Changes
                </button>
                <button type="button" onclick="document.getElementById('modal-edit').classList.add('hidden')"
                        class="px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-100 rounded-xl transition-colors">
                    Cancel
                </button>
            </div>
        </form>
    </div>
</div>

@endsection

@push('scripts')
<script>
function openEditModal(id, plan) {
    const form = document.getElementById('edit-form');
    form.action = `/panel/plans/${id}`;

    form.querySelector('[name="name"]').value              = plan.name;
    form.querySelector('[name="price_monthly"]').value     = plan.price_monthly;
    form.querySelector('[name="price_yearly"]').value      = plan.price_yearly;
    form.querySelector('[name="max_products"]').value      = plan.max_products;
    form.querySelector('[name="max_orders_per_month"]').value = plan.max_orders_per_month;
    form.querySelector('[name="max_branches"]').value      = plan.max_branches;
    form.querySelector('[name="features_json"]').value     = plan.features_json ? JSON.stringify(plan.features_json) : '';
    form.querySelector('[name="is_active"]').checked       = plan.is_active;

    document.getElementById('modal-edit').classList.remove('hidden');
}
</script>
@endpush
