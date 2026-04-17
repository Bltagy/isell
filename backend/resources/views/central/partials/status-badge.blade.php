@php
    $map = [
        'active'    => ['bg-emerald-100 text-emerald-700', 'fa-circle-check'],
        'suspended' => ['bg-amber-100 text-amber-700',     'fa-ban'],
        'deleted'   => ['bg-red-100 text-red-700',         'fa-trash'],
        'expired'   => ['bg-slate-100 text-slate-600',     'fa-clock'],
        'cancelled' => ['bg-slate-100 text-slate-600',     'fa-xmark'],
    ];
    [$cls, $icon] = $map[$status] ?? ['bg-slate-100 text-slate-600', 'fa-circle'];
@endphp
<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium {{ $cls }}">
    <i class="fa-solid {{ $icon }} text-[10px]"></i> {{ ucfirst($status) }}
</span>
