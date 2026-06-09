<?php

namespace App\Services;

use Aws\S3\S3Client;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ExerciseGifCatalog
{
    /** @return list<string> */
    public function all(): array
    {
        $files = $this->fromS3Client();

        if ($files === []) {
            $files = $this->fromStorageDisk();
        }

        sort($files, SORT_NATURAL | SORT_FLAG_CASE);

        return array_values(array_unique($files));
    }

    /** @return list<string> */
    public function inFolder(string $folder): array
    {
        $prefix = trim($folder, '/') . '/';

        return array_values(array_filter(
            $this->all(),
            fn (string $file): bool => str_starts_with($file, $prefix)
        ));
    }

    public function exists(string $relative): bool
    {
        $normalized = ltrim($relative, '/');

        return in_array($normalized, $this->all(), true);
    }

    /** @return list<string> */
    private function fromS3Client(): array
    {
        $disk = config('filesystems.disks.public', []);

        if (($disk['driver'] ?? null) !== 's3') {
            return [];
        }

        $bucket = $disk['bucket'] ?? null;
        $endpoint = $disk['endpoint'] ?? null;
        $key = $disk['key'] ?? null;
        $secret = $disk['secret'] ?? null;

        if (!$bucket || !$endpoint || !$key || !$secret) {
            return [];
        }

        try {
            $client = new S3Client([
                'version' => 'latest',
                'region' => $disk['region'] ?? 'us-east-1',
                'endpoint' => $endpoint,
                'use_path_style_endpoint' => (bool) ($disk['use_path_style_endpoint'] ?? false),
                'credentials' => [
                    'key' => $key,
                    'secret' => $secret,
                ],
            ]);

            $files = [];
            $params = [
                'Bucket' => $bucket,
                'Prefix' => 'exercises/',
            ];

            do {
                $result = $client->listObjectsV2($params);

                foreach (($result['Contents'] ?? []) as $object) {
                    $keyName = (string) ($object['Key'] ?? '');
                    if (! preg_match('/\.gif$/i', $keyName)) {
                        continue;
                    }

                    $files[] = Str::after($keyName, 'exercises/');
                }

                $params['ContinuationToken'] = $result['NextContinuationToken'] ?? null;
            } while (! empty($params['ContinuationToken']));

            return $files;
        } catch (\Throwable) {
            return [];
        }
    }

    /** @return list<string> */
    private function fromStorageDisk(): array
    {
        try {
            return collect(Storage::disk('public')->allFiles('exercises'))
                ->filter(fn (string $file): bool => (bool) preg_match('/\.gif$/i', $file))
                ->map(fn (string $file): string => Str::after($file, 'exercises/'))
                ->values()
                ->all();
        } catch (\Throwable) {
            return [];
        }
    }
}
