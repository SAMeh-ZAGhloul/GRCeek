#!/bin/bash

# Add Homebrew library path to the dynamic linker path for weasyprint
export DYLD_LIBRARY_PATH="/opt/homebrew/lib:/usr/local/lib:$DYLD_LIBRARY_PATH"

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Backend Setup ---
echo "Setting up and running the backend..."
cd backend

# Prepare meta file
VERSION=$(git describe --tags --always)
BUILD=$(git rev-parse --short HEAD)
echo "CISO_ASSISTANT_VERSION=${VERSION}" > ciso_assistant/.meta
echo "CISO_ASSISTANT_BUILD=${BUILD}" >> ciso_assistant/.meta
cp ciso_assistant/.meta .

# Install backend dependencies if not already installed
if [ ! -d ".venv" ]; then
    poetry install
fi

# Set environment variables for the backend
export ALLOWED_HOSTS="localhost"
export CISO_ASSISTANT_URL="https://localhost:8443"
export DJANGO_DEBUG="True"
export AUTH_TOKEN_TTL="7200"

# Apply database migrations
poetry run python manage.py migrate

# Create superuser if not exists
if ! poetry run python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); exit(0) if User.objects.filter(is_superuser=True).exists() else exit(1)"; then
    echo "Creating superuser..."
    poetry run python manage.py createsuperuser
fi

# Start the Django development server in the background
poetry run python manage.py runserver &
BACKEND_PID=$!
cd ..

# --- Huey Setup ---
echo "Setting up and running Huey..."
cd backend

# Set environment variables for Huey
export ALLOWED_HOSTS="localhost"
export CISO_ASSISTANT_URL="https://localhost:8443"
export DJANGO_DEBUG="False"
export AUTH_TOKEN_TTL="7200"

# Start the Huey worker in the background
poetry run python manage.py run_huey -w 2 --scheduler-interval 60 &
HUEY_PID=$!
cd ..

# --- Frontend Setup ---
echo "Setting up and running the frontend..."
cd frontend

# Install frontend dependencies if not already installed
if [ ! -d "node_modules" ]; then
    pnpm install
fi

# Set environment variables for the frontend
export PUBLIC_BACKEND_API_URL="http://localhost:8000/api"
export PUBLIC_BACKEND_API_EXPOSED_URL="https://localhost:8443/api"
export PROTOCOL_HEADER="x-forwarded-proto"
export HOST_HEADER="x-forwarded-host"

# Start the frontend development server in the background
pnpm run dev &
FRONTEND_PID=$!
cd ..

# --- Caddy Setup ---
echo "Setting up and running Caddy..."

# Check if Caddy is installed
if ! command -v caddy &> /dev/null
then
    echo "Caddy could not be found. Please install Caddy to run the reverse proxy."
    echo "See https://caddyserver.com/docs/install for installation instructions."
    # Clean up background processes before exiting
    kill $BACKEND_PID $HUEY_PID $FRONTEND_PID
    exit 1
fi

# Create Caddyfile
cat > Caddyfile.local <<EOL
${CISO_ASSISTANT_URL} {
    reverse_proxy /api/* localhost:8000
    reverse_proxy /* localhost:5173
    tls internal
}
EOL

# Start Caddy in the background
caddy run --config Caddyfile.local &
CADDY_PID=$!

echo "All services are running."
echo "Backend PID: $BACKEND_PID"
echo "Huey PID: $HUEY_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "Caddy PID: $CADDY_PID"
echo "Access the application at https://localhost:8443"

# --- Cleanup ---
# Function to clean up background processes on exit
cleanup() {
    echo "Shutting down services..."
    kill $BACKEND_PID $HUEY_PID $FRONTEND_PID $CADDY_PID
    rm Caddyfile.local
    echo "Cleanup complete."
}

# Trap script exit and call cleanup
trap cleanup EXIT

# Wait for all background processes to complete
# This will keep the script running until it's manually stopped (e.g., with Ctrl+C)
wait
