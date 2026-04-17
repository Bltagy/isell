<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'email'    => 'nullable|email',
            'phone'    => 'nullable|string',
            'password' => 'required|string',
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            if (empty($this->email) && empty($this->phone)) {
                $v->errors()->add('email', 'Either phone or email is required.');
            }
        });
    }
}
