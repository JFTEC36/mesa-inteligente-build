#!/bin/bash

# Script de correção de permissões Docker + Deploy
# Executar com: ./build.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}📌 $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# ============================================
# 1. VERIFICA E CORRIGE PERMISSÕES DO DOCKER
# ============================================
log_info "Verificando permissões do Docker..."

# Verifica se docker está instalado
if ! command -v docker &> /dev/null; then
    log_error "Docker não encontrado!"
    exit 1
fi

# Tenta conectar ao Docker
if ! docker ps &> /dev/null; then
    log_warning "Usuário atual não tem permissão para acessar o Docker."
    
    # Verifica se grupo docker existe
    if ! getent group docker > /dev/null; then
        log_info "Criando grupo docker..."
        sudo groupadd docker
    fi
    
    # Adiciona usuário ao grupo docker
    log_info "Adicionando $USER ao grupo docker..."
    sudo usermod -aG docker $USER
    
    log_success "Usuário adicionado ao grupo docker!"
    log_warning "É NECESSÁRIO REINICIAR A SESSÃO para aplicar as permissões."
    
    # Oferece opções para o usuário
    echo ""
    echo "Escolha uma opção:"
    echo "1) Sair e fazer logout/login manualmente (recomendado)"
    echo "2) Aplicar grupo temporariamente (newgrp) e continuar"
    echo "3) Usar sudo para executar o deploy (não recomendado)"
    read -p "Opção (1/2/3): " opt
    
    case $opt in
        1)
            log_info "Execute 'exit' para sair, faça login novamente e execute ./build.sh"
            exit 0
            ;;
        2)
            log_info "Aplicando grupo temporariamente..."
            exec newgrp docker "$0"  # Reexecuta o script com novo grupo
            ;;
        3)
            log_warning "Usando sudo (pode causar problemas de permissão em arquivos)"
            # Reexecuta com sudo, mantendo variáveis de ambiente
            exec sudo -E "$0"
            ;;
        *)
            log_error "Opção inválida"
            exit 1
            ;;
    esac
else
    log_success "Permissões Docker OK!"
fi

# ============================================
# 2. VERIFICA DOCKER COMPOSE
# ============================================
log_info "Verificando Docker Compose..."

if ! docker compose version &> /dev/null; then
    log_error "Docker Compose não disponível"
    exit 1
fi

# ============================================
# 3. CLONE/PULL DO REPOSITÓRIO
# ============================================
REPO_URL="https://github.com/JFTEC36/mesa-inteligente.git"
PROJECT_DIR="mesa-inteligente"

if [ -d "$PROJECT_DIR" ]; then
    log_info "Repositório já existe. Atualizando..."
    cd "$PROJECT_DIR"
    git pull
else
    log_info "Clonando repositório..."
    git clone "$REPO_URL"
    cd "$PROJECT_DIR"
fi

log_success "Repositório atualizado!"

# ============================================
# 4. VERIFICA ARQUIVOS DE CONFIGURAÇÃO
# ============================================
log_info "Verificando arquivos de configuração..."

if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml não encontrado!"
    exit 1
fi

# Cria .env se necessário
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    log_warning "Criando .env a partir de .env.example"
    cp .env.example .env
    echo "🔧 Edite o arquivo .env com suas configurações e execute novamente"
    exit 0
fi

# ============================================
# 5. DEPLOY
# ============================================
log_info "Parando containers existentes..."
docker compose down 2>/dev/null || true

log_info "Buildando imagens..."
export DOCKER_BUILDKIT=1
docker compose build

log_info "Iniciando containers..."
docker compose up -d

log_info "Aguardando serviços iniciarem (10s)..."
sleep 10

# ============================================
# 6. VERIFICAÇÃO
# ============================================
log_info "Verificando containers em execução..."
docker compose ps

# ============================================
# 7. LIMPEZA
# ============================================
log_info "Limpando imagens antigas..."
docker image prune -f

# ============================================
# 8. RESUMO
# ============================================
echo ""
log_success "🎉 DEPLOY CONCLUÍDO!"
echo ""
echo "📊 Status:"
docker compose ps
echo ""
echo "📋 Logs:"
echo "   docker compose logs -f"
echo ""
echo "🔄 Reiniciar:"
echo "   docker compose restart"
echo ""
echo "🛑 Parar:"
echo "   docker compose down"