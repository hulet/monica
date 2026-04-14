ARG GIT_COMMIT=unknown
FROM node:20-bookworm AS builder
ARG GIT_COMMIT

# Install PHP (needed for `php artisan lang:generate` pre-build step and composer)
RUN apt-get update && apt-get install -y \
    php8.2 php8.2-xml php8.2-mbstring php8.2-zip php8.2-curl php8.2-intl php8.2-bcmath php8.2-gd php8.2-gmp php8.2-sqlite3 \
    unzip git \
    && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# Install PHP dependencies
# --ignore-platform-reqs skips ext-redis and ext-apcu which are runtime-only
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# `yarn run production` has a pre-script that runs `php artisan lang:generate`,
# which requires a minimal Laravel env to bootstrap.
RUN echo "APP_KEY=base64:$(php -r 'echo base64_encode(random_bytes(32));')" > .env \
    && echo "DB_CONNECTION=sqlite" >> .env \
    && echo "DB_DATABASE=/tmp/build.sqlite" >> .env \
    && touch /tmp/build.sqlite

# Install JS dependencies and compile assets
RUN yarn run inst && yarn run production

# Remove the temporary build-only .env; runtime env comes from docker-compose
RUN rm .env

# Write the git commit hash so it appears in the footer
RUN echo -n "$GIT_COMMIT" > config/.commit


FROM lscr.io/linuxserver/monica:latest
COPY --chown=abc:abc --from=builder /app /app/www
