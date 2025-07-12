# LOCALLINK - Диагностика и исправление проблем с init-db.sql

Write-Host "🔍 LOCALLINK - Диагностика и исправление" -ForegroundColor Cyan
Write-Host ""

function Write-Step {
    param([string]$Text)
    Write-Host "[STEP] " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Success {
    param([string]$Text)
    Write-Host "[✅] " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Error {
    param([string]$Text)
    Write-Host "[❌] " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[⚠️] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Info {
    param([string]$Text)
    Write-Host "[📋] " -ForegroundColor Blue -NoNewline
    Write-Host $Text -ForegroundColor White
}

Write-Step "1. Остановка всех контейнеров..."
docker-compose down --remove-orphans --volumes

Write-Step "2. Диагностика файла init-db.sql..."

# Проверяем, что существует
if (Test-Path "init-db.sql") {
    $item = Get-Item "init-db.sql"

    if ($item.PSIsContainer) {
        Write-Error "init-db.sql является ДИРЕКТОРИЕЙ, а не файлом!"
        Write-Warning "Удаляем директорию и создаем правильный файл..."
        Remove-Item "init-db.sql" -Recurse -Force
    } else {
        Write-Success "init-db.sql является файлом"
        Write-Info "Размер: $($item.Length) байт"
    }
} else {
    Write-Warning "Файл init-db.sql не найден"
}

Write-Step "3. Создание правильного init-db.sql..."

# Создаем правильный init-db.sql файл
$initDbContent = @"
-- Инициализация PostGIS расширений для LOCALLINK
-- Этот файл автоматически выполняется при создании контейнера БД

-- Установка правильной кодировки
SET CLIENT_ENCODING TO 'UTF8';

-- Создание PostGIS расширений безопасно
DO `$`$
BEGIN
    -- Проверяем и создаем postgis
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        CREATE EXTENSION postgis;
        RAISE NOTICE 'PostGIS extension created';
    ELSE
        RAISE NOTICE 'PostGIS extension already exists';
    END IF;

    -- Проверяем и создаем postgis_topology
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis_topology') THEN
        CREATE EXTENSION postgis_topology;
        RAISE NOTICE 'PostGIS Topology extension created';
    ELSE
        RAISE NOTICE 'PostGIS Topology extension already exists';
    END IF;

    -- Проверяем и создаем fuzzystrmatch
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'fuzzystrmatch') THEN
        CREATE EXTENSION fuzzystrmatch;
        RAISE NOTICE 'Fuzzystrmatch extension created';
    ELSE
        RAISE NOTICE 'Fuzzystrmatch extension already exists';
    END IF;

    RAISE NOTICE 'PostGIS initialization completed successfully';

END `$`$;

-- Проверка успешной установки
SELECT 'PostGIS Version: ' || PostGIS_Version() as info;
"@

# Записываем содержимое в файл
$initDbContent | Out-File -FilePath "init-db.sql" -Encoding UTF8 -NoNewline

Write-Success "Файл init-db.sql создан успешно"

Write-Step "4. Проверка созданного файла..."
if (Test-Path "init-db.sql") {
    $item = Get-Item "init-db.sql"
    Write-Success "Файл существует, размер: $($item.Length) байт"
    Write-Info "Первые строки файла:"
    Get-Content "init-db.sql" -TotalCount 5 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Error "Файл не был создан!"
    exit 1
}

Write-Step "5. Проверка docker-compose.yml..."
if (Test-Path "docker-compose.yml") {
    $composeContent = Get-Content "docker-compose.yml" -Raw

    if ($composeContent -match "init-db\.sql") {
        Write-Success "docker-compose.yml содержит ссылку на init-db.sql"
    } else {
        Write-Warning "docker-compose.yml не содержит ссылку на init-db.sql"
        Write-Info "Возможно, потребуется обновить docker-compose.yml"
    }
} else {
    Write-Error "docker-compose.yml не найден!"
    exit 1
}

Write-Step "6. Очистка Docker кэша..."
docker system prune -f
docker volume prune -f

Write-Step "7. Сборка образов..."
docker-compose build --no-cache db

Write-Step "8. Запуск только БД для тестирования..."
docker-compose up -d db

Write-Info "Ожидание готовности PostgreSQL..."
$maxAttempts = 30
$attempt = 0

do {
    $attempt++
    Write-Host "." -NoNewline -ForegroundColor Yellow

    $dbReady = docker-compose exec -T db pg_isready -U postgres -d locallink_api_dev 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Success "PostgreSQL готов! (попытка $attempt)"
        break
    }

    Start-Sleep -Seconds 2
} while ($attempt -lt $maxAttempts)

if ($attempt -eq $maxAttempts) {
    Write-Host ""
    Write-Error "PostgreSQL не готов через $($maxAttempts * 2) секунд"
    Write-Info "Проверяем логи БД..."
    docker-compose logs db
    exit 1
}

Write-Step "9. Проверка PostGIS в базе данных..."
try {
    $checkPostGIS = docker-compose exec -T db psql -U postgres -d locallink_api_dev -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis');" -t 2>$null

    if ($checkPostGIS -match "t") {
        Write-Success "PostGIS успешно установлен в БД!"

        # Показываем версию PostGIS
        $version = docker-compose exec -T db psql -U postgres -d locallink_api_dev -c "SELECT PostGIS_Version();" -t 2>$null
        Write-Info "Версия PostGIS: $($version.Trim())"

        # Показываем все установленные расширения
        Write-Info "Установленные PostGIS расширения:"
        $extensions = docker-compose exec -T db psql -U postgres -d locallink_api_dev -c "SELECT extname FROM pg_extension WHERE extname LIKE '%postgis%' OR extname = 'fuzzystrmatch';" -t 2>$null
        $extensions -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
            Write-Host "   - $($_.Trim())" -ForegroundColor Green
        }

    } else {
        Write-Warning "PostGIS не найден в БД"
        Write-Info "Проверяем логи БД для диагностики..."
        docker-compose logs db | Select-Object -Last 10
    }
} catch {
    Write-Warning "Не удалось проверить PostGIS: $_"
}

Write-Step "10. Остановка БД и запуск всех сервисов..."
docker-compose down
docker-compose up -d

Write-Info "Ожидание готовности всех сервисов..."
Start-Sleep -Seconds 10

Write-Step "11. Финальная проверка через API..."
$maxAttempts = 20
$attempt = 0

do {
    $attempt++
    Write-Host "." -NoNewline -ForegroundColor Yellow

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4000/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host ""
            Write-Success "API готов! (попытка $attempt)"

            # Парсим JSON ответ
            $healthData = $response.Content | ConvertFrom-Json
            Write-Info "Статус API: $($healthData.status)"
            Write-Info "Статус БД: $($healthData.database)"

            if ($healthData.database -eq "ok") {
                Write-Success "База данных работает корректно!"
            } else {
                Write-Warning "Проблемы с базой данных: $($healthData.database)"
            }
            break
        }
    }
    catch {
        # Игнорируем ошибки подключения
    }

    Start-Sleep -Seconds 3
} while ($attempt -lt $maxAttempts)

if ($attempt -eq $maxAttempts) {
    Write-Host ""
    Write-Error "API не готов через $($maxAttempts * 3) секунд"
    Write-Info "Проверяем логи..."
    Write-Host ""
    Write-Host "=== ЛОГИ WEB ===" -ForegroundColor Yellow
    docker-compose logs --tail=10 web
    Write-Host ""
    Write-Host "=== ЛОГИ DB ===" -ForegroundColor Yellow
    docker-compose logs --tail=10 db
}

Write-Host ""
Write-Host "📊 Статус всех сервисов:" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
if ($attempt -lt $maxAttempts) {
    Write-Host "🎉 Исправление завершено успешно!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Требуется дополнительная диагностика" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔗 Проверьте работу:" -ForegroundColor Cyan
Write-Host "   curl http://localhost:4000/health" -ForegroundColor Gray
Write-Host "   curl http://localhost:4000/api/v1/posts" -ForegroundColor Gray
