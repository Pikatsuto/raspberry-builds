# Docker Service First-Boot Initialization
# Creates Portainer and Watchtower containers

echo "[DOCKER] Initializing Docker containers..."

# Create Portainer
echo "  Creating Portainer container..."
docker volume create portainer_data
docker run -d \
    -p 8000:8000 -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -l hidden=true \
    portainer/portainer-ce:lts

# Create Watchtower
echo "  Creating Watchtower container..."
docker run -d \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -l hidden=true \
    -e WATCHTOWER_SCHEDULE="0 0 4 * * *" \
    --restart always \
    containrrr/watchtower

echo "[DOCKER] Docker containers initialized successfully!"