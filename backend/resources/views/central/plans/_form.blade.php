{{-- Shared form fields for create/edit plan modals --}}
<div>
    <label class="block text-xs font-medium text-slate-700 mb-1.5">Plan Name <span class="text-red-500">*</span></label>
    <input type="text" name="name" required
           class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500"
           placeholder="e.g. Starter, Pro, Enterprise">
</div>

<div class="grid grid-cols-2 gap-4">
    <div>
        <label class="block text-xs font-medium text-slate-700 mb-1.5">Monthly Price (piastres) <span class="text-red-500">*</span></label>
        <input type="number" name="price_monthly" min="0" required
               class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500"
               placeholder="e.g. 9900 = 99 EGP">
    </div>
    <div>
        <label class="block text-xs font-medium text-slate-700 mb-1.5">Yearly Price (piastres) <span class="text-red-500">*</span></label>
        <input type="number" name="price_yearly" min="0" required
               class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500"
               placeholder="e.g. 99000 = 990 EGP">
    </div>
</div>

<div class="grid grid-cols-3 gap-4">
    <div>
        <label class="block text-xs font-medium text-slate-700 mb-1.5">Max Products</label>
        <input type="number" name="max_products" min="1" value="100" required
               class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500">
    </div>
    <div>
        <label class="block text-xs font-medium text-slate-700 mb-1.5">Max Orders/mo</label>
        <input type="number" name="max_orders_per_month" min="1" value="1000" required
               class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500">
    </div>
    <div>
        <label class="block text-xs font-medium text-slate-700 mb-1.5">Max Branches</label>
        <input type="number" name="max_branches" min="1" value="1" required
               class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500">
    </div>
</div>

<div>
    <label class="block text-xs font-medium text-slate-700 mb-1.5">Features (JSON array)</label>
    <textarea name="features_json" rows="2"
              class="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 font-mono"
              placeholder='["Analytics", "Priority Support", "Custom Domain"]'></textarea>
    <p class="text-xs text-slate-400 mt-1">Optional. Enter a JSON array of feature strings.</p>
</div>

<div class="flex items-center gap-2">
    <input type="checkbox" name="is_active" id="is_active_{{ isset($edit) ? 'edit' : 'create' }}" value="1" checked
           class="rounded border-slate-300 text-sky-500 focus:ring-sky-500">
    <label for="is_active_{{ isset($edit) ? 'edit' : 'create' }}" class="text-sm text-slate-700">Active (visible to tenants)</label>
</div>
