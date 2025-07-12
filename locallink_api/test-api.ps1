# LOCALLINK - API Testing Script
# Quick API testing and demonstration

param(
    [Parameter(Position=0)]
    [ValidateSet('health', 'register', 'login', 'posts', 'create-post', 'events', 'hot-zones', 'full-demo', 'help')]
    [string]$Command = 'help',

    [string]$Email = "test@locallink.uz",
    [string]$Password = "password123",
    [string]$BaseUrl = "http://localhost:4000"
)

# Глобальная переменная для токена
$Global:AuthToken = $null

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "[TEST] " -ForegroundColor Green -NoNewline
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

function Write-Info {
    param([string]$Text)
    Write-Host "[📋] " -ForegroundColor Blue -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Show-Help {
    Write-Header "🧪 LOCALLINK API Testing Tool"

    Write-Host @"
ИСПОЛЬЗОВАНИЕ:
    .\test-api.ps1 <команда> [параметры]

КОМАНДЫ:
    health       🏥 Проверить статус API
    register     👤 Зарегистрировать тестового пользователя
    login        🔐 Войти в систему
    posts        📋 Получить список постов
    create-post  ➕ Создать тестовый пост
    events       🎉 Получить список событий
    hot-zones    🔥 Получить горячие зоны
    full-demo    🎬 Полная демонстрация API
    help         ❓ Показать эту справку

ПАРАМЕТРЫ:
    -Email       Email для регистрации/входа (по умолчанию: test@locallink.uz)
    -Password    Пароль (по умолчанию: password123)
    -BaseUrl     Базовый URL API (по умолчанию: http://localhost:4000)

ПРИМЕРЫ:
    .\test-api.ps1 health                                    # Проверка статуса
    .\test-api.ps1 register -Email "user@test.com"          # Регистрация
    .\test-api.ps1 full-demo                                 # Полная демонстрация
"@ -ForegroundColor Gray
}

function Test-APIHealth {
    Write-Step "Проверка состояния API..."

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 10

        Write-Success "API работает!"
        Write-Host "  Status: " -NoNewline
        Write-Host $response.status -ForegroundColor Green
        Write-Host "  Database: " -NoNewline
        Write-Host $response.database -ForegroundColor $(if($response.database -eq "ok") {"Green"} else {"Red"})
        Write-Host "  Version: " -NoNewline
        Write-Host $response.version -ForegroundColor Cyan
        Write-Host "  Timestamp: " -NoNewline
        Write-Host $response.timestamp -ForegroundColor Gray

        return $true
    }
    catch {
        Write-Error "API недоступен: $($_.Exception.Message)"
        Write-Info "Убедитесь, что сервер запущен: .\start.ps1"
        return $false
    }
}

function Register-TestUser {
    param([string]$UserEmail, [string]$UserPassword)

    Write-Step "Регистрация пользователя: $UserEmail"

    $body = @{
        user = @{
            email = $UserEmail
            password = $UserPassword
            first_name = "Тест"
            last_name = "Пользователь"
            phone = "+998901234567"
        }
    } | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/register" -Method POST -Body $body -ContentType "application/json"

        Write-Success "Пользователь зарегистрирован!"
        Write-Host "  ID: " -NoNewline
        Write-Host $response.user.id -ForegroundColor Cyan
        Write-Host "  Email: " -NoNewline
        Write-Host $response.user.email -ForegroundColor Cyan
        Write-Host "  Name: " -NoNewline
        Write-Host "$($response.user.first_name) $($response.user.last_name)" -ForegroundColor Cyan

        # Сохраняем токен
        $Global:AuthToken = $response.token
        Write-Info "Токен авторизации сохранен"

        return $response
    }
    catch {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($errorDetails) {
            Write-Error "Ошибка регистрации: $($errorDetails.error)"
            if ($errorDetails.errors) {
                foreach ($field in $errorDetails.errors.PSObject.Properties) {
                    Write-Host "  $($field.Name): $($field.Value -join ', ')" -ForegroundColor Red
                }
            }
        } else {
            Write-Error "Ошибка регистрации: $($_.Exception.Message)"
        }
        return $null
    }
}

function Login-User {
    param([string]$UserEmail, [string]$UserPassword)

    Write-Step "Вход пользователя: $UserEmail"

    $body = @{
        email = $UserEmail
        password = $UserPassword
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/login" -Method POST -Body $body -ContentType "application/json"

        Write-Success "Вход выполнен успешно!"
        Write-Host "  ID: " -NoNewline
        Write-Host $response.user.id -ForegroundColor Cyan
        Write-Host "  Email: " -NoNewline
        Write-Host $response.user.email -ForegroundColor Cyan

        # Сохраняем токен
        $Global:AuthToken = $response.token
        Write-Info "Токен авторизации сохранен"

        return $response
    }
    catch {
        Write-Error "Ошибка входа: $($_.Exception.Message)"
        return $null
    }
}

function Get-Posts {
    Write-Step "Получение списка постов..."

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/posts" -Method GET

        Write-Success "Найдено постов: $($response.posts.Count)"

        foreach ($post in $response.posts | Select-Object -First 5) {
            Write-Host ""
            Write-Host "📋 " -ForegroundColor Blue -NoNewline
            Write-Host $post.title -ForegroundColor White
            Write-Host "   Категория: " -NoNewline
            Write-Host $post.category -ForegroundColor Yellow
            Write-Host "   Локация: " -NoNewline
            Write-Host $post.location -ForegroundColor Cyan
            if ($post.price) {
                Write-Host "   Цена: " -NoNewline
                Write-Host "$($post.price) $($post.currency)" -ForegroundColor Green
            }
            Write-Host "   Автор: " -NoNewline
            Write-Host "$($post.user.first_name) $($post.user.last_name)" -ForegroundColor Magenta
        }

        if ($response.posts.Count -gt 5) {
            Write-Host ""
            Write-Info "... и еще $($response.posts.Count - 5) постов"
        }

        return $response.posts
    }
    catch {
        Write-Error "Ошибка получения постов: $($_.Exception.Message)"
        return $null
    }
}

function Create-TestPost {
    if (-not $Global:AuthToken) {
        Write-Error "Требуется авторизация. Выполните сначала login или register"
        return $null
    }

    Write-Step "Создание тестового поста..."

    $headers = @{
        "Authorization" = "Bearer $Global:AuthToken"
        "Content-Type" = "application/json"
    }

    $body = @{
        post = @{
            title = "🔧 Тестовый пост от PowerShell"
            description = "Этот пост создан автоматически для тестирования API. Нужен мастер для мелкого ремонта."
            category = "task"
            post_type = "seeking"
            location = "Ташкент, Мирзо-Улугбек"
            urgency = "today"
            price = 150000
            currency = "UZS"
            skills_required = "Мелкий ремонт"
            duration_estimate = "2-3 часа"
        }
    } | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/posts" -Method POST -Body $body -Headers $headers

        Write-Success "Пост создан!"
        Write-Host "  ID: " -NoNewline
        Write-Host $response.post.id -ForegroundColor Cyan
        Write-Host "  Заголовок: " -NoNewline
        Write-Host $response.post.title -ForegroundColor White
        Write-Host "  Категория: " -NoNewline
        Write-Host $response.post.category -ForegroundColor Yellow
        Write-Host "  Цена: " -NoNewline
        Write-Host "$($response.post.price) $($response.post.currency)" -ForegroundColor Green

        return $response.post
    }
    catch {
        Write-Error "Ошибка создания поста: $($_.Exception.Message)"
        return $null
    }
}

function Get-Events {
    Write-Step "Получение доступных событий..."

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/events/available" -Method GET

        Write-Success "Найдено событий: $($response.events.Count)"

        foreach ($event in $response.events) {
            Write-Host ""
            Write-Host "🎉 " -ForegroundColor Yellow -NoNewline
            Write-Host $event.title -ForegroundColor White
            Write-Host "   Дата: " -NoNewline
            Write-Host $event.event_date -ForegroundColor Cyan
            Write-Host "   Участники: " -NoNewline
            Write-Host "$($event.current_participants)/$($event.max_participants)" -ForegroundColor Green
            Write-Host "   Локация: " -NoNewline
            Write-Host $event.location -ForegroundColor Cyan
            if ($event.price) {
                Write-Host "   Цена: " -NoNewline
                Write-Host "$($event.price) $($event.currency)" -ForegroundColor Green
            }
        }

        return $response.events
    }
    catch {
        Write-Error "Ошибка получения событий: $($_.Exception.Message)"
        return $null
    }
}

function Get-HotZones {
    Write-Step "Получение горячих зон..."

    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/v1/hot-zones" -Method GET

        Write-Success "Найдено горячих зон: $($response.hot_zones.Count)"

        foreach ($zone in $response.hot_zones) {
            Write-Host ""
            Write-Host "🔥 " -ForegroundColor Red -NoNewline
            Write-Host "Горячая зона" -ForegroundColor White
            Write-Host "   Постов: " -NoNewline
            Write-Host $zone.post_count -ForegroundColor Yellow
            Write-Host "   Координаты: " -NoNewline
            Write-Host $zone.center -ForegroundColor Cyan
        }

        return $response.hot_zones
    }
    catch {
        Write-Error "Ошибка получения горячих зон: $($_.Exception.Message)"
        return $null
    }
}

function Run-FullDemo {
    Write-Header "🎬 Полная демонстрация API LOCALLINK"

    Write-Host "Этот скрипт продемонстрирует основные возможности API:" -ForegroundColor Gray
    Write-Host "1. Проверка статуса API" -ForegroundColor Gray
    Write-Host "2. Регистрация нового пользователя" -ForegroundColor Gray
    Write-Host "3. Получение списка постов" -ForegroundColor Gray
    Write-Host "4. Создание нового поста" -ForegroundColor Gray
    Write-Host "5. Получение событий" -ForegroundColor Gray
    Write-Host "6. Получение горячих зон" -ForegroundColor Gray
    Write-Host ""

    $confirm = Read-Host "Продолжить демонстрацию? (Y/n)"
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Info "Демонстрация отменена"
        return
    }

    # 1. Проверка статуса
    Write-Host ""
    Write-Host "🏥 ШАГ 1: Проверка статуса API" -ForegroundColor Yellow
    $healthOk = Test-APIHealth
    if (-not $healthOk) {
        Write-Error "API недоступен. Остановка демонстрации."
        return
    }

    Start-Sleep -Seconds 2

    # 2. Регистрация
    Write-Host ""
    Write-Host "👤 ШАГ 2: Регистрация пользователя" -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $testEmail = "demo_$timestamp@locallink.uz"
    $user = Register-TestUser -UserEmail $testEmail -UserPassword $Password

    if (-not $user) {
        Write-Info "Попробуем войти с существующим аккаунтом..."
        $user = Login-User -UserEmail $Email -UserPassword $Password
    }

    Start-Sleep -Seconds 2

    # 3. Получение постов
    Write-Host ""
    Write-Host "📋 ШАГ 3: Получение списка постов" -ForegroundColor Yellow
    $posts = Get-Posts

    Start-Sleep -Seconds 2

    # 4. Создание поста
    if ($Global:AuthToken) {
        Write-Host ""
        Write-Host "➕ ШАГ 4: Создание нового поста" -ForegroundColor Yellow
        $newPost = Create-TestPost
        Start-Sleep -Seconds 2
    }

    # 5. События
    Write-Host ""
    Write-Host "🎉 ШАГ 5: Получение событий" -ForegroundColor Yellow
    $events = Get-Events

    Start-Sleep -Seconds 2

    # 6. Горячие зоны
    Write-Host ""
    Write-Host "🔥 ШАГ 6: Получение горячих зон" -ForegroundColor Yellow
    $hotZones = Get-HotZones

    # Итоги
    Write-Header "🎉 Демонстрация завершена!"

    Write-Host "📊 " -ForegroundColor Blue -NoNewline
    Write-Host "Статистика:" -ForegroundColor White
    if ($posts) { Write-Host "   📋 Постов найдено: $($posts.Count)" -ForegroundColor Gray }
    if ($events) { Write-Host "   🎉 События найдены: $($events.Count)" -ForegroundColor Gray }
    if ($hotZones) { Write-Host "   🔥 Горячих зон: $($hotZones.Count)" -ForegroundColor Gray }
    if ($Global:AuthToken) { Write-Host "   🔐 Авторизация: активна" -ForegroundColor Green }

    Write-Host ""
    Write-Host "🔗 " -ForegroundColor Cyan -NoNewline
    Write-Host "Полезные ссылки:" -ForegroundColor White
    Write-Host "   API Health: $BaseUrl/health" -ForegroundColor Gray
    Write-Host "   Posts API: $BaseUrl/api/v1/posts" -ForegroundColor Gray
    Write-Host "   Events API: $BaseUrl/api/v1/events/available" -ForegroundColor Gray
}

# ========================================
# ОСНОВНАЯ ЛОГИКА
# ========================================

switch ($Command.ToLower()) {
    'health' {
        Write-Header "🏥 Проверка статуса API"
        Test-APIHealth | Out-Null
    }
    'register' {
        Write-Header "👤 Регистрация пользователя"
        Register-TestUser -UserEmail $Email -UserPassword $Password | Out-Null
    }
    'login' {
        Write-Header "🔐 Вход в систему"
        Login-User -UserEmail $Email -UserPassword $Password | Out-Null
    }
    'posts' {
        Write-Header "📋 Список постов"
        Get-Posts | Out-Null
    }
    'create-post' {
        Write-Header "➕ Создание поста"
        Create-TestPost | Out-Null
    }
    'events' {
        Write-Header "🎉 События"
        Get-Events | Out-Null
    }
    'hot-zones' {
        Write-Header "🔥 Горячие зоны"
        Get-HotZones | Out-Null
    }
    'full-demo' {
        Run-FullDemo
    }
    'help' {
        Show-Help
    }
    default {
        Write-Error "Неизвестная команда: $Command"
        Show-Help
    }
}
