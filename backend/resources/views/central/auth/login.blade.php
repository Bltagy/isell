<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Super Admin Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
</head>
<body class="h-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center p-4">

<div class="w-full max-w-md">

    {{-- Card --}}
    <div class="bg-white rounded-2xl shadow-2xl overflow-hidden">

        {{-- Header --}}
        <div class="bg-gradient-to-r from-slate-900 to-slate-700 px-8 py-8 text-center">
            <div class="w-14 h-14 rounded-2xl bg-sky-500 flex items-center justify-center mx-auto mb-4 shadow-lg">
                <i class="fa-solid fa-store text-white text-xl"></i>
            </div>
            <h1 class="text-white text-xl font-bold">Super Admin Panel</h1>
            <p class="text-slate-400 text-sm mt-1">Central tenant management</p>
        </div>

        {{-- Form --}}
        <div class="px-8 py-8">

            @if($errors->any())
                <div class="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-3 rounded-xl mb-5">
                    <i class="fa-solid fa-circle-exclamation"></i>
                    {{ $errors->first() }}
                </div>
            @endif

            <form method="POST" action="{{ route('central.login.post') }}" class="space-y-5">
                @csrf

                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-1.5">Email address</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                            <i class="fa-solid fa-envelope text-sm"></i>
                        </span>
                        <input type="email" name="email" value="{{ old('email') }}" required autofocus
                               class="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 focus:border-transparent transition"
                               placeholder="admin@example.com">
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-1.5">Password</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                            <i class="fa-solid fa-lock text-sm"></i>
                        </span>
                        <input type="password" name="password" required
                               class="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-sky-500 focus:border-transparent transition"
                               placeholder="••••••••">
                    </div>
                </div>

                <div class="flex items-center gap-2">
                    <input type="checkbox" name="remember" id="remember" class="rounded border-slate-300 text-sky-500 focus:ring-sky-500">
                    <label for="remember" class="text-sm text-slate-600">Remember me</label>
                </div>

                <button type="submit"
                        class="w-full bg-sky-600 hover:bg-sky-700 text-white font-semibold py-2.5 rounded-xl transition-colors shadow-sm text-sm">
                    Sign in to Panel
                </button>
            </form>
        </div>
    </div>

    <p class="text-center text-slate-500 text-xs mt-6">Super Admin access only &mdash; unauthorized access is prohibited.</p>
</div>

</body>
</html>
