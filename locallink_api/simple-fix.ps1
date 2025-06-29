# simple-fix.ps1 - Simple fix without complex functions

Write-Host "=====================================" -ForegroundColor Green
Write-Host "LocalLink API - Simple Fix" -ForegroundColor Green  
Write-Host "=====================================" -ForegroundColor Green

# Check we're in the right place
if (!(Test-Path "mix.exs")) {
    Write-Host "ERROR: Not in locallink_api folder!" -ForegroundColor Red
    Write-Host "Current location: $PWD" -ForegroundColor Yellow
    Write-Host "Please navigate to locallink_api folder first" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found mix.exs - we're in the right place" -ForegroundColor Green

# Stop containers
docker-compose down 2>$null

# Clean up
Write-Host "Cleaning up old files..." -ForegroundColor Yellow
if (Test-Path "lib/locallink_api/guardian") { Remove-Item "lib/locallink_api/guardian" -Recurse -Force }
if (Test-Path "lib/locallink_api/guardian.ex") { Remove-Item "lib/locallink_api/guardian.ex" -Force }
if (Test-Path "lib/locallink_api_web/controllers/HealthController.ex") { Remove-Item "lib/locallink_api_web/controllers/HealthController.ex" -Force }
if (Test-Path "lib/locallink_api_web/controllers/health_controller.ex") { Remove-Item "lib/locallink_api_web/controllers/health_controller.ex" -Force }
if (Test-Path "lib/locallink_api_web/router.ex") { Remove-Item "lib/locallink_api_web/router.ex" -Force }
if (Test-Path "lib/locallink_web") { Remove-Item "lib/locallink_web" -Recurse -Force }

# Create directories step by step
Write-Host "Creating directories..." -ForegroundColor Yellow

if (!(Test-Path "lib")) { 
    Write-Host "ERROR: lib directory not found!" -ForegroundColor Red
    exit 1 
}

if (!(Test-Path "lib/locallink_api")) { 
    Write-Host "ERROR: lib/locallink_api directory not found!" -ForegroundColor Red
    exit 1 
}

if (!(Test-Path "lib/locallink_api_web")) { 
    Write-Host "ERROR: lib/locallink_api_web directory not found!" -ForegroundColor Red
    exit 1 
}

# Create guardian directory
if (!(Test-Path "lib/locallink_api/guardian")) {
    New-Item -ItemType Directory -Path "lib/locallink_api/guardian" -Force | Out-Null
}

# Create controllers directory
if (!(Test-Path "lib/locallink_api_web/controllers")) {
    New-Item -ItemType Directory -Path "lib/locallink_api_web/controllers" -Force | Out-Null
}

# Verify directories exist
if (!(Test-Path "lib/locallink_api/guardian")) {
    Write-Host "ERROR: Failed to create lib/locallink_api/guardian" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "lib/locallink_api_web/controllers")) {
    Write-Host "ERROR: Failed to create lib/locallink_api_web/controllers" -ForegroundColor Red  
    exit 1
}

Write-Host "✓ Directories created successfully" -ForegroundColor Green

# Create files using simple method
Write-Host "Creating files..." -ForegroundColor Yellow

# 1. auth_pipeline.ex
Write-Host "Creating auth_pipeline.ex..." -ForegroundColor Yellow
$content = 'defmodule LocallinkApi.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :locallink_api,
    error_handler: LocallinkApi.Guardian.AuthErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource
end'

$content | Set-Content -Path "lib/locallink_api/guardian/auth_pipeline.ex" -Encoding UTF8

# 2. auth_error_handler.ex
Write-Host "Creating auth_error_handler.ex..." -ForegroundColor Yellow
$content = 'defmodule LocallinkApi.Guardian.AuthErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  def init(opts), do: opts

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: to_string(type)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end'

$content | Set-Content -Path "lib/locallink_api/guardian/auth_error_handler.ex" -Encoding UTF8

# 3. health_controller.ex
Write-Host "Creating health_controller.ex..." -ForegroundColor Yellow
$content = 'defmodule LocallinkApiWeb.HealthController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Repo

  def check(conn, _params) do
    db_status = 
      try do
        Ecto.Adapters.SQL.query!(Repo, "SELECT 1", [])
        "ok"
      rescue
        _ -> "error"
      end

    health_data = %{
      status: (if db_status == "ok", do: "healthy", else: "unhealthy"),
      timestamp: DateTime.utc_now(),
      version: "1.0.0",
      database: db_status
    }

    status_code = if health_data.status == "healthy", do: 200, else: 503

    conn
    |> put_status(status_code)
    |> json(health_data)
  end
end'

$content | Set-Content -Path "lib/locallink_api_web/controllers/health_controller.ex" -Encoding UTF8

# 4. router.ex
Write-Host "Creating router.ex..." -ForegroundColor Yellow
$content = 'defmodule LocallinkApiWeb.Router do
  use LocallinkApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :auth do
    plug LocallinkApi.Guardian.AuthPipeline
  end

  scope "/", LocallinkApiWeb do
    pipe_through :api
    
    get "/health", HealthController, :check
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, :auth]

    get "/me", AuthController, :me
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
    get "/my-posts", PostController, :my_posts
  end
end'

$content | Set-Content -Path "lib/locallink_api_web/router.ex" -Encoding UTF8

Write-Host "✓ All files created" -ForegroundColor Green

# Verify files
Write-Host "Verifying files..." -ForegroundColor Yellow
$files = @(
    "lib/locallink_api/guardian/auth_pipeline.ex",
    "lib/locallink_api/guardian/auth_error_handler.ex",
    "lib/locallink_api_web/controllers/health_controller.ex",
    "lib/locallink_api_web/router.ex"
)

$allOk = $true
foreach ($file in $files) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  ✓ $file ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ MISSING: $file" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "Some files are missing! Please create them manually in VS Code." -ForegroundColor Red
    exit 1
}

# Build
Write-Host ""
Write-Host "Building Docker image..." -ForegroundColor Yellow
Write-Host "This takes 3-4 minutes..." -ForegroundColor Yellow

docker-compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host ""
    Write-Host "If you see BOM errors, you need to create files manually:" -ForegroundColor Yellow
    Write-Host "1. Open VS Code" -ForegroundColor White
    Write-Host "2. Create each file manually" -ForegroundColor White
    Write-Host "3. Save as UTF-8 (NOT UTF-8 with BOM)" -ForegroundColor White
    exit 1
}

Write-Host "✓ BUILD SUCCESSFUL!" -ForegroundColor Green

# Start
Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
docker-compose up -d

# Wait
Write-Host "Waiting 2 minutes for startup..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

# Test
Write-Host "Testing API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4000/health" -TimeoutSec 20
    Write-Host ""
    Write-Host "🎉 SUCCESS! API IS WORKING!" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "API not responding yet. Check logs:" -ForegroundColor Yellow
    Write-Host "docker-compose logs -f api" -ForegroundColor White
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host ""
Write-Host "Available Services:" -ForegroundColor Cyan
Write-Host "  API: http://localhost:4000" -ForegroundColor White
Write-Host "  Health: http://localhost:4000/health" -ForegroundColor White
Write-Host "  Posts: http://localhost:4000/api/v1/posts" -ForegroundColor White
Write-Host "  DB Admin: http://localhost:8080" -ForegroundColor White

Write-Host ""
Write-Host "Test Commands:" -ForegroundColor Cyan
Write-Host "  Invoke-WebRequest http://localhost:4000/health" -ForegroundColor White
Write-Host "  Invoke-WebRequest http://localhost:4000/api/v1/posts" -ForegroundColor White

Write-Host ""
Write-Host "Management:" -ForegroundColor Cyan
Write-Host "  docker-compose logs -f api" -ForegroundColor White
Write-Host "  docker-compose restart api" -ForegroundColor White
Write-Host "  docker-compose down" -ForegroundColor White
Write-Host ""