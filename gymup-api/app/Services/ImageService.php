<?php

namespace App\Services;

use App\Models\Reward;
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
    public function store(UploadedFile $file, string $folder = 'uploads'): string
    {
        $image = $this->manager()->read($file->getRealPath());

        // 1. Redimensiona mantendo proporção
        if ($image->width() > self::MAX_DIMENSION || $image->height() > self::MAX_DIMENSION) {
            $image->scaleDown(self::MAX_DIMENSION, self::MAX_DIMENSION);
        }

        // 2. Converte para WebP com qualidade iterativa
        $quality  = self::QUALITY_START;
        $encoded  = $image->toWebp($quality);

        while (strlen((string) $encoded) > self::MAX_SIZE_BYTES && $quality > 10) {
            $quality -= 5;
            $encoded  = $image->toWebp($quality);
        }

        // 3. Salva e retorna apenas o path relativo (ex: rewards/uuid.webp)
        $path = $folder . '/' . Str::uuid() . '.webp';

        $stored = Storage::disk('public')->put($path, (string) $encoded, [
            'visibility'  => 'public',
            'ContentType' => 'image/webp',
        ]);

        if (!$stored) {
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
            Storage::disk('public')->delete($path);
        }
    }
}
