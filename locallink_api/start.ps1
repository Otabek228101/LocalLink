
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
Write-Host "=====================================" -ForegroundColor Green
Write-Host "LocalLink API - Start" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

if (!(Test-Path "docker-compose.yml")) {
    Write-Host "ERROR: docker-compose.yml not found. Run this script from the locallink_api folder." -ForegroundColor Red
    exit 1
}

Write-Host "Building Docker images..." -ForegroundColor Yellow

docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Starting containers..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start containers" -ForegroundColor Red
    exit 1
}

Write-Host "✓ API is starting at http://localhost:4000" -ForegroundColor Green
Write-Host "Use 'docker-compose logs -f api' to view logs" -ForegroundColor Cyan

