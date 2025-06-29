# start-server.ps1 - Start LocalLink API server

Write-Host "=========================================" -ForegroundColor Green
Write-Host "LocalLink API - Starting Server" -ForegroundColor Green  
Write-Host "=========================================" -ForegroundColor Green

# Check if we're in the right directory
if (!(Test-Path "mix.exs")) {
    Write-Host "ERROR: mix.exs not found. Make sure you're in locallink_api folder" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "docker-compose.yml")) {
    Write-Host "ERROR: docker-compose.yml not found" -ForegroundColor Red
    exit 1
}

Write-Host "Found mix.exs and docker-compose.yml - we're in the right folder" -ForegroundColor Green

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker not installed" -ForegroundColor Red
    exit 1
}

if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker Compose not installed" -ForegroundColor Red
    exit 1
}

Write-Host "Docker and Docker Compose found" -ForegroundColor Green

# Stop any existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

# Build Docker image
Write-Host "Building Docker image (this may take several minutes)..." -ForegroundColor Yellow
Write-Host "Please wait..." -ForegroundColor Yellow

$startTime = Get-Date
docker-compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed!" -ForegroundColor Red
    Write-Host "Check the error messages above" -ForegroundColor Yellow
    exit 1
}

$buildTime = (Get-Date) - $startTime
Write-Host "Docker build completed in $($buildTime.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Green

# Start services
Write-Host "Starting services..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to start services!" -ForegroundColor Red
    Write-Host "Running docker-compose logs for details..." -ForegroundColor Yellow
    docker-compose logs
    exit 1
}

Write-Host "Services started successfully!" -ForegroundColor Green

# Wait for services to be ready
Write-Host "Waiting for services to start (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Check container status
Write-Host ""
Write-Host "Container Status:" -ForegroundColor Cyan
docker-compose ps

# Check if containers are running
$containers = docker-compose ps --format json | ConvertFrom-Json
$runningContainers = $containers | Where-Object { $_.State -eq "running" }
$totalContainers = ($containers | Measure-Object).Count
$runningCount = ($runningContainers | Measure-Object).Count

Write-Host ""
Write-Host "Container Summary: $runningCount/$totalContainers containers running" -ForegroundColor Cyan

if ($runningCount -eq 0) {
    Write-Host "ERROR: No containers are running!" -ForegroundColor Red
    Write-Host "Showing logs for debugging:" -ForegroundColor Yellow
    docker-compose logs
    exit 1
}

# Check PostgreSQL specifically
$postgresContainer = $containers | Where-Object { $_.Service -eq "postgres" }
if ($postgresContainer -and $postgresContainer.State -eq "running") {
    Write-Host "PostgreSQL: Running" -ForegroundColor Green
} else {
    Write-Host "PostgreSQL: NOT running" -ForegroundColor Red
}

# Check API container specifically  
$apiContainer = $containers | Where-Object { $_.Service -eq "api" }
if ($apiContainer -and $apiContainer.State -eq "running") {
    Write-Host "API: Running" -ForegroundColor Green
} else {
    Write-Host "API: NOT running" -ForegroundColor Red
    Write-Host "API logs:" -ForegroundColor Yellow
    docker-compose logs api
}

# Test API health endpoint
Write-Host ""
Write-Host "Testing API health endpoint..." -ForegroundColor Yellow

$apiReady = $false
for ($i = 1; $i -le 10; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4000/health" -TimeoutSec 10 -ErrorAction Stop
        Write-Host "SUCCESS! API is responding!" -ForegroundColor Green
        Write-Host "Health response: $($response.Content)" -ForegroundColor Cyan
        $apiReady = $true
        break
    } catch {
        Write-Host "Attempt $i/10: API not ready yet..." -ForegroundColor Yellow
        if ($i -lt 10) {
            Start-Sleep -Seconds 15
        }
    }
}

if (-not $apiReady) {
    Write-Host "WARNING: API is not responding after 2.5 minutes" -ForegroundColor Yellow
    Write-Host "This might be normal - API can take 3-5 minutes to fully start" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "API container logs (last 30 lines):" -ForegroundColor Yellow
    docker-compose logs --tail=30 api
    Write-Host ""
    Write-Host "Try checking again in 2-3 minutes:" -ForegroundColor Yellow
    Write-Host "Invoke-WebRequest http://localhost:4000/health" -ForegroundColor White
}

# Test Posts endpoint if API is ready
if ($apiReady) {
    Write-Host ""
    Write-Host "Testing Posts API..." -ForegroundColor Yellow
    try {
        $postsResponse = Invoke-WebRequest -Uri "http://localhost:4000/api/v1/posts" -TimeoutSec 10 -ErrorAction Stop
        Write-Host "Posts API is working!" -ForegroundColor Green
        
        # Parse JSON to check if we have posts
        $postsData = $postsResponse.Content | ConvertFrom-Json
        if ($postsData.posts) {
            $postCount = ($postsData.posts | Measure-Object).Count
            Write-Host "Found $postCount posts in database" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Posts API not ready yet (database might still be initializing)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Server Status Summary" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

if ($apiReady) {
    Write-Host "✅ API Server: RUNNING" -ForegroundColor Green
} else {
    Write-Host "⏳ API Server: STARTING (wait 2-3 more minutes)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Available Services:" -ForegroundColor Cyan
Write-Host "  🔗 API: http://localhost:4000" -ForegroundColor White
Write-Host "  🔗 Health Check: http://localhost:4000/health" -ForegroundColor White  
Write-Host "  🔗 Posts API: http://localhost:4000/api/v1/posts" -ForegroundColor White
Write-Host "  🔗 Database Admin: http://localhost:8080" -ForegroundColor White

Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  📜 View API logs: docker-compose logs -f api" -ForegroundColor White
Write-Host "  📜 View all logs: docker-compose logs" -ForegroundColor White
Write-Host "  🔄 Restart API: docker-compose restart api" -ForegroundColor White
Write-Host "  🛑 Stop all: docker-compose down" -ForegroundColor White

Write-Host ""
Write-Host "Test Commands:" -ForegroundColor Cyan
Write-Host "  Invoke-WebRequest http://localhost:4000/health" -ForegroundColor White
Write-Host "  Invoke-WebRequest http://localhost:4000/api/v1/posts" -ForegroundColor White

Write-Host ""
if ($apiReady) {
    Write-Host "🎉 LocalLink API is ready for development!" -ForegroundColor Green
} else {
    Write-Host "⏳ LocalLink API is starting... check again in a few minutes" -ForegroundColor Yellow
}
Write-Host ""