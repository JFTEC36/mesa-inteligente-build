#!/bin/bash

# Script de instalação automatizada - Docker + GitHub CLI + Traefik ready
set -e

echo "🚀 Iniciando instalação automatizada..."

# Cores para mensagens
print_message() { echo -e "\033[1;34m➡️  $1\033[0m"; }
print_success() { echo -e "\033[1;32m✅ $1\033[0m"; }
print_error() { echo -e "\033[1;31m❌ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

# Verifica usuário não-root
if [ "$EUID" -eq 0 ]; then 
    print_error "Não execute este script como root. Use um usuário com sudo."
    exit 1
fi

# ============================================
# PARTE 1: INSTALANDO GITHUB CLI
# ============================================
print_message "Instalando GitHub CLI..."
sudo apt update
sudo apt install -y wget gnupg

sudo mkdir -p -m 755 /etc/apt/keyrings
wget -nv -O /tmp/ghcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
sudo install -o root -g root -m 644 /tmp/ghcli.gpg /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt update
sudo apt install -y gh

print_success "GitHub CLI instalado: $(gh --version | head -n1)"

# ============================================
# PARTE 2: INSTALANDO DOCKER
# ============================================
print_message "Instalando Docker Engine e componentes..."

sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

print_success "Docker instalado: $(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)"

# ============================================
# PARTE 3: PERMISSÕES DO DOCKER
# ============================================
print_message "Configurando permissões do Docker..."

sudo groupadd -f docker
sudo usermod -aG docker $USER

print_success "Usuário $USER adicionado ao grupo docker!"

# ============================================
# PARTE 4: TESTE DOCKER
# ============================================
print_message "Testando Docker..."
docker run hello-world || print_warning "Teste com hello-world falhou. Verifique manualmente."

# ============================================
# PARTE 5: CONFIGURAR DIRETÓRIO LETSENCRYPT PARA TRAEFIK
# ============================================
LE_DIR="$HOME/mesa-inteligente/letsencrypt"
print_message "Criando diretório de certificados do Traefik em $LE_DIR"
mkdir -p "$LE_DIR"
chmod 600 "$LE_DIR"
print_success "Diretório pronto!"

# ============================================
# PARTE 6: VERIFICAR DOCKER COMPOSE
# ============================================
print_message "Verificando docker compose..."
docker compose version || { print_error "docker compose não encontrado"; exit 1; }

# ============================================
# FIM
# ============================================
echo ""
print_success "🎉 INSTALAÇÃO CONCLUÍDA! Docker pronto para Traefik e Let's Encrypt"
print_warning "⚠️  Lembre-se de iniciar Traefik primeiro no projeto antes de subir api/frontend"
echo "   docker compose up -d traefik"
echo "Depois suba os demais serviços:"
echo "   docker compose up -d"
echo ""
echo "💡 Comandos de teste:"
echo "   docker --version"
echo "   docker compose version"
echo "   docker run hello-world"