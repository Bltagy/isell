<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class ImageUploadService
{
    private ImageManager $manager;

    public function __construct()
    {
        $this->manager = new ImageManager(new Driver());
    }

    /**
     * Upload an image, resize to max 800x600, convert to WebP, store in MinIO.
     *
     * @param  UploadedFile  $file
     * @param  string  $folder
     * @return string  Public URL of the stored image
     */
    public function upload(UploadedFile $file, string $folder = 'products'): string
    {
        $encoded = $this->manager
            ->read($file->getRealPath())
            ->scaleDown(width: 800, height: 600)
            ->toWebp(quality: 85);

        $path = $this->buildPath($folder);
        Storage::disk('s3')->put($path, (string) $encoded, 'public');

        return Storage::disk('s3')->url($path);
    }

    /**
     * Upload an image and also create a 200x200 thumbnail.
     *
     * @param  UploadedFile  $file
     * @param  string  $folder
     * @return array{url: string, thumbnail_url: string}
     */
    public function uploadWithThumbnail(UploadedFile $file, string $folder = 'products'): array
    {
        $realPath = $file->getRealPath();

        // Main image — max 800×600
        $main = $this->manager
            ->read($realPath)
            ->scaleDown(width: 800, height: 600)
            ->toWebp(quality: 85);

        $mainPath = $this->buildPath($folder);
        Storage::disk('s3')->put($mainPath, (string) $main, 'public');

        // Thumbnail — 200×200 cover crop
        $thumb = $this->manager
            ->read($realPath)
            ->cover(width: 200, height: 200)
            ->toWebp(quality: 80);

        $thumbPath = $this->buildPath($folder . '/thumbnails');
        Storage::disk('s3')->put($thumbPath, (string) $thumb, 'public');

        return [
            'url'           => Storage::disk('s3')->url($mainPath),
            'thumbnail_url' => Storage::disk('s3')->url($thumbPath),
        ];
    }

    /**
     * Delete a file from the S3/MinIO disk by its storage path.
     *
     * @param  string  $path  Storage path (not the full URL)
     */
    public function delete(string $path): void
    {
        Storage::disk('s3')->delete($path);
    }

    /**
     * Build a unique storage path for the given folder.
     */
    private function buildPath(string $folder): string
    {
        return trim($folder, '/') . '/' . Str::uuid() . '.webp';
    }
}
