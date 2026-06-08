# Imagem base com PHP 8.4
FROM php:8.4-cli

# Instala bibliotecas do sistema e as extensões do PHP que o Laravel + PostgreSQL precisam
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libonig-dev \
 && docker-php-ext-install pdo_pgsql pgsql mbstring zip bcmath \
 && rm -rf /var/lib/apt/lists/*

# Instala o Composer (gerenciador de pacotes do PHP)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Pasta de trabalho dentro do container
WORKDIR /var/www

# Copia o código da API pra dentro do container
COPY . .

# Instala as dependências do Laravel (sem as de desenvolvimento)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Permissão pras pastas que o Laravel precisa escrever
RUN chmod -R 775 storage bootstrap/cache

# Sobe a API quando o container inicia: roda as migrations e inicia o servidor na porta que o Render manda
CMD php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=$PORT
