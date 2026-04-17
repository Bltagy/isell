<?php

namespace App\Mail;

use App\Models\Tenant;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class WelcomeTenantMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly Tenant $tenant,
        public readonly string $adminEmail,
        public readonly string $adminPassword,
        public readonly string $domain,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Welcome to the Platform — Your Store is Ready!',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.tenant.welcome',
        );
    }
}
