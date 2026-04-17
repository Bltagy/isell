<?php

namespace Tests\Feature;

use App\Mail\WelcomeTenantMail;
use App\Models\Tenant;
use App\Services\TenantService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Stancl\Tenancy\Jobs\CreateDatabase;
use Stancl\Tenancy\Jobs\MigrateDatabase;
use Stancl\Tenancy\Jobs\SeedDatabase;
use Tests\TestCase;

class TenantProvisioningTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Prevent actual DB creation/migration/seeding during tests
        $this->mock(CreateDatabase::class);
        $this->mock(MigrateDatabase::class);
        $this->mock(SeedDatabase::class);

        Mail::fake();
    }

    public function test_provisioning_creates_tenant_in_central_db(): void
    {
        $service = app(TenantService::class);

        $tenant = $service->provision([
            'name'  => 'Test Restaurant',
            'email' => 'owner@testrestaurant.com',
        ]);

        $this->assertDatabaseHas('tenants', [
            'name'   => 'Test Restaurant',
            'email'  => 'owner@testrestaurant.com',
            'status' => 'active',
        ]);
    }

    public function test_provisioning_creates_domain_with_subdomain(): void
    {
        $service = app(TenantService::class);

        $tenant = $service->provision([
            'name'  => 'Pizza Palace',
            'email' => 'owner@pizzapalace.com',
            'slug'  => 'pizza-palace',
        ]);

        $this->assertDatabaseHas('domains', [
            'tenant_id'  => $tenant->id,
            'is_primary' => true,
        ]);

        $domain = $tenant->domains()->first();
        $this->assertStringContainsString('pizza-palace', $domain->domain);
    }

    public function test_provisioning_dispatches_welcome_email(): void
    {
        $service = app(TenantService::class);

        $service->provision([
            'name'  => 'Burger Joint',
            'email' => 'owner@burgerjoint.com',
        ]);

        Mail::assertQueued(WelcomeTenantMail::class, function ($mail) {
            return $mail->adminEmail === 'owner@burgerjoint.com';
        });
    }
}
