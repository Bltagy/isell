<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name'                  => 'required|string|max:255',
            'email'                 => 'nullable|email|unique:users,email',
            'phone'                 => 'required|string|unique:users,phone',
            'password'              => 'required|string|min:8|confirmed',
            'preferred_language'    => 'nullable|in:en,ar',
        ];
    }
}
