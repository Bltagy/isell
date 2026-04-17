@extends('central.layouts.app')

@section('title', 'New Tenant')
@section('page-title', 'Provision New Tenant')
@section('page-subtitle', 'Create a new tenant and provision their database')

@section('content')

<div class="max-w-2xl">
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="px-6 py-5 border-b border-slate-100">
            <h3 class="font-semibold text-slate-800">Tenant Details</h3>
            <p class="text-xs text-slate-500 mt-0.5">This will create the tenant record, provision a database, and send a welcome email.</p>
        </div>

        <form method="POST" action="{{ route('central.tenants.store') }}" class="px-6 py-6 space-y-5">
            @csrf

            <div>
                <label class="block text-sm font-medium text-slate-700 mb-1.5">
                    Business Name <span class="text-red-500">*</span>
                </label>
                <input type="text" name="name" value="{{ old('name') }}" required
                       class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 @error('name') border-red-400 @enderror"
                       placeholder="e.g. Burger Palace">
                @error('name')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
            </div>

            <div>
                <label class="block text-sm font-medium text-slate-700 mb-1.5">
                    Admin Email <span class="text-red-500">*</span>
                </label>
                <input type="email" name="email" value="{{ old('email') }}" required
                       class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 @error('email') border-red-400 @enderror"
                       placeholder="admin@burgerpalace.com">
                <p class="text-xs text-slate-400 mt-1">Login credentials will be sent to this address.</p>
                @error('email')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
            </div>

            <div>
                <label class="block text-sm font-medium text-slate-700 mb-1.5">
                    Subdomain Slug <span class="text-slate-400 font-normal">(optional)</span>
                </label>
                <div class="flex items-center border border-slate-300 rounded-xl overflow-hidden focus-within:ring-2 focus-within:ring-sky-500 @error('slug') border-red-400 @enderror">
                    <input type="text" name="slug" value="{{ old('slug') }}"
                           class="flex-1 px-4 py-2.5 text-sm focus:outline-none"
                           placeholder="burger-palace">
                    <span class="px-3 py-2.5 bg-slate-50 text-slate-500 text-sm border-l border-slate-300">
                        .{{ config('app.domain', 'yourdomain.com') }}
                    </span>
                </div>
                <p class="text-xs text-slate-400 mt-1">Leave blank to auto-generate from name. Only letters, numbers, and hyphens.</p>
                @error('slug')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
            </div>

            <div class="flex items-center gap-3 pt-2">
                <button type="submit"
                        class="inline-flex items-center gap-2 bg-sky-600 hover:bg-sky-700 text-white text-sm font-medium px-5 py-2.5 rounded-xl transition-colors shadow-sm">
                    <i class="fa-solid fa-rocket"></i> Provision Tenant
                </button>
                <a href="{{ route('central.tenants') }}"
                   class="text-sm text-slate-600 hover:text-slate-800 px-4 py-2.5 rounded-xl hover:bg-slate-100 transition-colors">
                    Cancel
                </a>
            </div>
        </form>
    </div>
</div>

@endsection
