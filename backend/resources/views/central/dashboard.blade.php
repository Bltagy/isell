@extends('central.layouts.app')

@section('title', 'Dashboard')
@section('page-title', 'Dashboard')
@section('page-subtitle', 'Platform overview and key metrics')

@section('content')

{{-- ── Stats Grid ──────────────────────────────────────────── --}}
<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">

    @php
        $cards = [
            ['label' => 'Total Tenants',     'value' => $stats['total_tenants'],     'icon' => 'fa-building',      'color' => 'bg-violet-500',  'bg' => 'bg-violet-50',  'text' => 'text-violet-700'],
            ['label' => 'Active Tenants',    'value' => $stats['active_tenants'],    'icon' => 'fa-circle-check',  'color' => 'bg-emerald-500', 'bg' => 'bg-emerald-50', 'text' => 'text-emerald-700'],
            ['label' => 'Suspended',         'value' => $stats['suspended_tenants'], 'icon' => 'fa-ban',           'color' => 'bg-amber-500',   'bg' => 'bg-amber-50',   'text' => 'text-amber-700'],
            ['label' => 'MRR (EGP)',         'value' => number_format($stats['mrr'] / 100, 2), 'icon' => 'fa-coins', 'color' => 'bg-sky-500', 'bg' => 'bg-sky-50', 'text' => 'text-sky-700'],
        ];
    @endphp

    @foreach($cards as $card)
    <div class="bg-white rounded-2xl p-5 shadow-sm border border-slate-100 flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl {{ $card['color'] }} flex items-center justify-center shadow-sm flex-shrink-0">
            <i class="fa-solid {{ $card['icon'] }} text-white"></i>
        </div>
        <div>
            <p class="text-2xl font-bold text-slate-800">{{ $card['value'] }}</p>
            <p class="text-xs text-slate-500 mt-0.5">{{ $card['label'] }}</p>
        </div>
    </div>
    @endforeach
</div>

{{-- ── Charts Row ───────────────────────────────────────────── --}}
<div class="grid grid-cols-1 xl:grid-cols-3 gap-5 mb-8">

    {{-- Signups Chart --}}
    <div class="xl:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <div class="flex items-center justify-between mb-5">
            <div>
                <h3 class="font-semibold text-slate-800">New Signups</h3>
                <p class="text-xs text-slate-500 mt-0.5">Last 6 months</p>
            </div>
        </div>
        <canvas id="signupsChart" height="100"></canvas>
    </div>

    {{-- Plans Breakdown --}}
    <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <h3 class="font-semibold text-slate-800 mb-1">Plans Breakdown</h3>
        <p class="text-xs text-slate-500 mb-5">Active subscriptions per plan</p>
        <canvas id="plansChart" height="200"></canvas>
        <div class="mt-4 space-y-2">
            @foreach($plansBreakdown as $plan)
            <div class="flex items-center justify-between text-sm">
                <span class="text-slate-600 truncate">{{ $plan->name }}</span>
                <span class="font-semibold text-slate-800 ml-2">{{ $plan->active_count }}</span>
            </div>
            @endforeach
        </div>
    </div>
</div>

{{-- ── Recent Tenants ───────────────────────────────────────── --}}
<div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
    <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
        <h3 class="font-semibold text-slate-800">Recent Tenants</h3>
        <a href="{{ route('central.tenants') }}" class="text-xs text-sky-600 hover:text-sky-700 font-medium">View all →</a>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-slate-50 text-left">
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Tenant</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Domain</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Plan</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                    <th class="px-6 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Created</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($recentTenants as $tenant)
                <tr class="hover:bg-slate-50 transition-colors">
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-3">
                            <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-slate-700 to-slate-500 flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                                {{ strtoupper(substr($tenant->name, 0, 1)) }}
                            </div>
                            <div>
                                <p class="font-medium text-slate-800">{{ $tenant->name }}</p>
                                <p class="text-xs text-slate-400">{{ $tenant->email }}</p>
                            </div>
                        </div>
                    </td>
                    <td class="px-6 py-4 text-slate-600">{{ $tenant->primaryDomain?->domain ?? '—' }}</td>
                    <td class="px-6 py-4">
                        @if($tenant->activeSubscription)
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-sky-100 text-sky-700">
                                {{ $tenant->activeSubscription->plan?->name ?? 'Unknown' }}
                            </span>
                        @else
                            <span class="text-slate-400 text-xs">No plan</span>
                        @endif
                    </td>
                    <td class="px-6 py-4">
                        @include('central.partials.status-badge', ['status' => $tenant->trashed() ? 'deleted' : $tenant->status])
                    </td>
                    <td class="px-6 py-4 text-slate-500 text-xs">{{ $tenant->created_at?->diffForHumans() }}</td>
                </tr>
                @empty
                <tr><td colspan="5" class="px-6 py-10 text-center text-slate-400">No tenants yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
const signupsData = @json($signupsChart);
const plansData   = @json($plansBreakdown);

// Signups chart
new Chart(document.getElementById('signupsChart'), {
    type: 'bar',
    data: {
        labels: signupsData.map(d => d.month),
        datasets: [{
            label: 'New Tenants',
            data: signupsData.map(d => d.count),
            backgroundColor: 'rgba(14,165,233,0.15)',
            borderColor: 'rgba(14,165,233,1)',
            borderWidth: 2,
            borderRadius: 6,
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
            y: { beginAtZero: true, ticks: { stepSize: 1 }, grid: { color: 'rgba(0,0,0,0.04)' } },
            x: { grid: { display: false } }
        }
    }
});

// Plans doughnut
const palette = ['#0ea5e9','#8b5cf6','#10b981','#f59e0b','#ef4444','#6366f1'];
new Chart(document.getElementById('plansChart'), {
    type: 'doughnut',
    data: {
        labels: plansData.map(p => p.name),
        datasets: [{
            data: plansData.map(p => p.active_count),
            backgroundColor: palette,
            borderWidth: 0,
            hoverOffset: 6,
        }]
    },
    options: {
        responsive: true,
        cutout: '70%',
        plugins: { legend: { display: false } }
    }
});
</script>
@endpush
