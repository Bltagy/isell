SHELL := /bin/sh

COMPOSE = docker compose

.PHONY: up down build bash shell migrate seed logs ps fresh horizon reverb tinker test artisan

## Start all containers
up:
	$(COMPOSE) --env-file .env up -d --build

## Build Docker images
build:
	$(COMPOSE) --env-file .env build

## Stop all containers
down:
	$(COMPOSE) down

## Shell into the app container
bash:
	$(COMPOSE) exec laravel-app bash

## Shell into the app container (alias for bash)
shell:
	$(COMPOSE) exec laravel-app bash

## Run migrations
migrate:
	$(COMPOSE) exec laravel-app php artisan migrate

## Run seeders
seed:
	$(COMPOSE) exec laravel-app php artisan db:seed

## Fresh migrate + seed
fresh:
	$(COMPOSE) exec laravel-app php artisan migrate:fresh --seed

## Follow logs
logs:
	$(COMPOSE) logs -f --tail=200

## Show running containers
ps:
	$(COMPOSE) ps

## Restart Horizon
horizon:
	$(COMPOSE) restart laravel-horizon

## Restart Reverb
reverb:
	$(COMPOSE) restart laravel-reverb

## Laravel Tinker
tinker:
	$(COMPOSE) exec laravel-app php artisan tinker

## Run tests
test:
	$(COMPOSE) exec laravel-app php artisan test

## Run any artisan command: make artisan cmd="route:list"
artisan:
	$(COMPOSE) exec laravel-app php artisan $(cmd)

## Clear all caches
clear:
	$(COMPOSE) exec laravel-app php artisan optimize:clear

## Generate app key
key:
	$(COMPOSE) exec laravel-app php artisan key:generate

## Create MinIO bucket
minio-setup:
	$(COMPOSE) exec laravel-app php artisan minio:setup

## ── Flutter ──────────────────────────────────────────────────────────────────
# Reads HOST_IP from .env automatically so you never hardcode the IP.
# Usage:
#   make flutter-run          # run on connected device/emulator
#   make flutter-run-android  # explicitly target Android
#   make flutter-apk          # build a debug APK

HOST_IP ?= $(shell grep '^HOST_IP=' .env | cut -d= -f2)
FLUTTER_BASE_URL ?= http://$(HOST_IP):8055

flutter-run:
	cd mobile && flutter run --dart-define=BASE_URL=$(FLUTTER_BASE_URL)

flutter-run-android:
	cd mobile && flutter run -d android --dart-define=BASE_URL=$(FLUTTER_BASE_URL)

flutter-apk:
	cd mobile && flutter build apk --dart-define=BASE_URL=$(FLUTTER_BASE_URL)

flutter-ios:
	cd mobile && flutter run -d ios --dart-define=BASE_URL=$(FLUTTER_BASE_URL)

## ── Backup & Restore ─────────────────────────────────────────────────────────
# Backup locally:              make backup
# Backup + push to remote:     make backup REMOTE=root@isell.dev-ark.com
# Restore on remote (run there): make restore FILE=backups/foodapp_backup_XYZ.tar.gz

REMOTE ?=

backup:
	./scripts/backup.sh $(REMOTE)

restore:
	./scripts/restore.sh $(FILE)
