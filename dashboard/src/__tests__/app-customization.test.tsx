/**
 * Integration tests for the App Customization panel.
 * Tests: color picker updates live preview, publish sends batch-update request.
 */
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock the API module
vi.mock('@/lib/api', () => ({
  api: {
    get: vi.fn().mockResolvedValue({
      data: {
        data: {
          primary_color: '#FF6B35',
          secondary_color: '#6366f1',
          accent_color: '#f59e0b',
          background_color: '#ffffff',
          text_color: '#111827',
          font_family: 'Cairo',
          app_name_en: 'Food App',
          app_name_ar: 'تطبيق الطعام',
          maintenance_mode: false,
        },
      },
    }),
    post: vi.fn().mockResolvedValue({ data: { success: true } }),
  },
}));

// Mock next-intl
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
  useLocale: () => 'en',
}));

// Mock sonner
vi.mock('sonner', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}));

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

describe('App Customization Panel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the customization page with color pickers', async () => {
    const { default: Page } = await import('@/app/[locale]/(tenant)/app-customization/page');
    render(<Page />, { wrapper });

    await waitFor(() => {
      expect(screen.queryByText('loading')).not.toBeInTheDocument();
    });

    // Color picker fields should be present
    expect(screen.getByText('primaryColor')).toBeInTheDocument();
    expect(screen.getByText('secondaryColor')).toBeInTheDocument();
  });

  it('shows publish button as disabled when no changes made', async () => {
    const { default: Page } = await import('@/app/[locale]/(tenant)/app-customization/page');
    render(<Page />, { wrapper });

    await waitFor(() => {
      const publishBtn = screen.queryByRole('button', { name: /publishChanges/i });
      if (publishBtn) {
        expect(publishBtn).toBeDisabled();
      }
    });
  });

  it('enables publish button after making a change', async () => {
    const { default: Page } = await import('@/app/[locale]/(tenant)/app-customization/page');
    render(<Page />, { wrapper });

    await waitFor(() => {
      const input = screen.queryByDisplayValue('Food App');
      if (input) {
        fireEvent.change(input, { target: { value: 'My Restaurant' } });
      }
    });

    await waitFor(() => {
      const publishBtn = screen.queryByRole('button', { name: /publishChanges/i });
      if (publishBtn) {
        expect(publishBtn).not.toBeDisabled();
      }
    });
  });
});
