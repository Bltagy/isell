<?php

namespace App\Http\Controllers\Central;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CentralAuthController extends Controller
{
    public function showLogin()
    {
        if (Auth::guard('central')->check()) {
            return redirect()->route('central.dashboard');
        }
        return view('central.auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::guard('central')->attempt(
            $request->only('email', 'password'),
            $request->boolean('remember')
        )) {
            $user = Auth::guard('central')->user();

            // Restrict to emails listed in SUPER_ADMIN_EMAILS env (comma-separated)
            $allowed = array_map('trim', explode(',', env('SUPER_ADMIN_EMAILS', '')));

            if (! empty(array_filter($allowed)) && ! in_array($user->email, $allowed, true)) {
                Auth::guard('central')->logout();
                return back()->withErrors(['email' => 'Access denied. Not a super admin.']);
            }

            $request->session()->regenerate();
            return redirect()->route('central.dashboard');
        }

        return back()->withErrors(['email' => 'Invalid credentials.'])->withInput();
    }

    public function logout(Request $request)
    {
        Auth::guard('central')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('central.login');
    }
}
