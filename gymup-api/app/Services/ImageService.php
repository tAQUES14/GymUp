<?php

namespace App\Services;

use App\Models\Reward;
use Aws\S3\S3Client;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Intervention\Image\ImageManager;
use Intervention\Image\Drivers\Gd\Driver;

class ImageService
{
    /**
     * Tamanho máximo da dimensão mais longa (largura ou altura).
     * A imagem é redimensionada proporcionalmente se ultrapassar esse valor.
     */
    private const MAX_DIMENSION = 1200;

    /**
     * Qualidade WebP inicial. Será reduzida iterativamente até atingir MAX_SIZE_BYTES.
     */
    private const QUALITY_START = 85;

    /**
     * Tamanho máximo do arquivo final em bytes (1 MB).
     */
    private const MAX_SIZE_BYTES = 1_048_576; // 1 MB

    private ?ImageManager $manager = null;

    private function manager(): ImageManager
    {
        return $this->manager ??= new ImageManager(new Driver());
    }

    /**
     * Processa um arquivo de imagem enviado pelo usuário:
     *   1. Redimensiona para no máximo MAX_DIMENSION px na maior dimensão (mantendo proporção).
     *   2. Converte para WebP.
     *   3. Reduz a qualidade iterativamente até o arquivo ficar abaixo de 1 MB.
     *   4. Salva em storage/public/{folder}/ e retorna o path relativo (ex: rewards/uuid.webp).
     */
    public function store(
        UploadedFile $file,
        string $folder = 'uploads',
        int $maxDimension = self::MAX_DIMENSION,
        int $maxSizeBytes = self::MAX_SIZE_BYTES,
        int $qualityStart = self::QUALITY_START
    ): string
    {
        $image = $this->manager()->read($file->getRealPath());

        // 1. Redimensiona mantendo proporção
        if ($image->width() > $maxDimension || $image->height() > $maxDimension) {
            $image->scaleDown($maxDimension, $maxDimension);
        }

        // 2. Converte para WebP com qualidade iterativa
        $quality  = $qualityStart;
        $encoded  = $image->toWebp($quality);

        while (strlen((string) $encoded) > $maxSizeBytes && $quality > 10) {
            $quality -= 5;
            $encoded  = $image->toWebp($quality);
        }

        // 3. Salva e retorna apenas o path relativo (ex: rewards/uuid.webp)
        $path = $folder . '/' . Str::uuid() . '.webp';

        if (!$this->put($path, (string) $encoded)) {
            throw new \RuntimeException('Nao foi possivel enviar a imagem para o storage publico.');
        }

        return $path;
    }

    /**
     * Remove um arquivo do storage. Aceita path relativo (rewards/x.webp)
     * ou URL absoluta (http://host/storage/rewards/x.webp).
     */
    public function delete(string $pathOrUrl): void
    {
        $path = Reward::normalizeImagePath($pathOrUrl);

        if ($path) {
            $this->deletePath($path);
        }
    }

    private function put(string $path, string $contents): bool
    {
        $client = $this->s3Client();
        $bucket = $this->publicDiskConfig()['bucket'] ?? null;

        if ($client && $bucket) {
            try {
                $client->putObject([
                    'Bucket'      => $bucket,
                    'Key'         => $path,
                    'Body'        => $contents,
                    'ContentType' => 'image/webp',
                ]);

                $client->headObject([
                    'Bucket' => $bucket,
                    'Key'    => $path,
                ]);

                return true;
            } catch (\Throwable) {
                return false;
            }
        }

        return (bool) Storage::disk('public')->put($path, $contents, [
            'visibility'  => 'public',
            'ContentType' => 'image/webp',
        ]);
    }

    private function deletePath(string $path): void
    {
        $client = $this->s3Client();
        $bucket = $this->publicDiskConfig()['bucket'] ?? null;

        if ($client && $bucket) {
            try {
                $client->deleteObject([
                    'Bucket' => $bucket,
                    'Key'    => $path,
                ]);

                return;
            } catch (\Throwable) {
                // Fall through to the Laravel disk fallback.
            }
        }

        Storage::disk('public')->delete($path);
    }

    private function s3Client(): ?S3Client
    {
        $disk = $this->publicDiskConfig();
        $bucket = $disk['bucket'] ?? null;
        $endpoint = $disk['endpoint'] ?? null;
        $key = $disk['key'] ?? null;
        $secret = $disk['secret'] ?? null;

        if (!$bucket || !$endpoint || !$key || !$secret) {
            return null;
        }

        return new S3Client([
            'version' => 'latest',
            'region' => $disk['region'] ?? 'us-east-1',
            'endpoint' => $endpoint,
            'use_path_style_endpoint' => (bool) ($disk['use_path_style_endpoint'] ?? false),
            'credentials' => [
                'key' => $key,
                'secret' => $secret,
            ],
        ]);
    }

    /** @return array<string, mixed> */
    private function publicDiskConfig(): array
    {
        return config('filesystems.disks.public', []);
    }
}
