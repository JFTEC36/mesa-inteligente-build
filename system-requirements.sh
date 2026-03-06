cat << 'EOF' > install-server.sh
#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

echo "🚀 Iniciando instalação automatizada..."

# ============================================
# CORES
# ============================================
print_message() { echo -e "\033[1;34m➡️  $1\033[0m"; }
print_success() { echo -e "\033[1;32m✅ $1\033[0m"; }
print_error() { echo -e "\033[1;31m❌ $1\033[0m"; }

# ============================================
# NÃO RODAR COMO ROOT
# ============================================
if [ "$EUID" -eq 0 ]; then
    print_error "Não execute como root"
    exit 1
fi

# ============================================
# LIMPAR REPOS DOCKER ANTIGO
# ============================================
print_message "Removendo repositórios Docker antigos..."

sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.*
sudo rm -f /usr/share/keyrings/docker*

# ============================================
# UPDATE BASE
# ============================================
print_message "Atualizando sistema..."

sudo apt update
sudo apt install -y wget curl gnupg ca-certificates lsb-release

# ============================================
# GITHUB CLI
# ============================================
print_message "Instalando GitHub CLI..."

sudo mkdir -p /etc/apt/keyrings

wget -nv -O /tmp/githubcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg

sudo install -o root -g root -m 644 /tmp/githubcli.gpg /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt update
sudo apt install -y gh

print_success "GitHub CLI instalado"

# ============================================
# DOCKER
# ============================================
print_message "Instalando Docker..."

sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

print_success "Docker instalado"

# ============================================
# CONFIG DOCKER
# ============================================
print_message "Configurando Docker..."

sudo groupadd -f docker
sudo usermod -aG docker $USER

sudo systemctl enable docker
sudo systemctl start docker

# ============================================
# TESTE
# ============================================
print_message "Testando Docker..."

docker run hello-world || true

# ============================================
# TRAEFIK LETSENCRYPT
# ============================================
print_message "Criando diretório letsencrypt..."

mkdir -p ~/mesa-inteligente/letsencrypt
touch ~/mesa-inteligente/letsencrypt/acme.json
chmod 600 ~/mesa-inteligente/letsencrypt/acme.json

# ============================================
# FINAL
# ============================================
echo ""
print_success "Instalação concluída!"
echo ""
echo "Execute para aplicar grupo docker:"
echo ""
echo "   newgrp docker"
echo ""
echo "Teste:"
echo ""
echo "   docker run hello-world"
echo ""

EOF
