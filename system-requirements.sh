#!/bin/bash

# Script de instalação automatizada - VERSÃO CORRIGIDA
# Instala GitHub CLI, Docker (repositório oficial) e configura permissões

set -e  # Interrompe o script em caso de erro

echo "🚀 Iniciando instalação automatizada..."

# Cores para mensagens
print_message() { echo -e "\033[1;34m➡️  $1\033[0m"; }
print_success() { echo -e "\033[1;32m✅ $1\033[0m"; }
print_error() { echo -e "\033[1;31m❌ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

# Verifica se não está como root
if [ "$EUID" -eq 0 ]; then 
    print_error "Não execute este script como root. Use um usuário com sudo."
    exit 1
fi

# Verifica sudo
if ! command -v sudo &> /dev/null; then
    print_error "sudo não está instalado."
    exit 1
fi

# ============================================
# PARTE 1: INSTALAÇÃO DO GITHUB CLI
# ============================================
print_message "Instalando GitHub CLI..."

# Instala wget se necessário
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

if [ $? -eq 0 ]; then
    print_success "Repositório do GitHub CLI configurado!"
else
    print_error "Falha ao configurar repositório do GitHub CLI."
    exit 1
fi

sudo apt update && sudo apt install gh -y

if command -v gh &> /dev/null; then
    print_success "GitHub CLI instalado! Versão: $(gh --version | head -n1)"
else
    print_error "Falha na instalação do GitHub CLI."
    exit 1
fi

# ============================================
# PARTE 2: INSTALAÇÃO DO DOCKER
# ============================================
print_message "Instalando Docker (repositório oficial)..."

# 2.1 Remove pacotes conflitantes (versões antigas/ubuntu)
print_message "Removendo versões conflitantes do Docker..."
sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true

# 2.2 Instala dependências necessárias
print_message "Instalando dependências..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 2.3 Adiciona a chave GPG oficial do Docker
print_message "Adicionando chave GPG do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 2.4 Adiciona o repositório oficial do Docker
print_message "Adicionando repositório Docker ao APT..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2.5 Atualiza lista de pacotes (agora com repositório Docker)
print_message "Atualizando lista de pacotes (repositório Docker adicionado)..."
sudo apt update

# 2.6 Instala o Docker Engine e componentes
print_message "Instalando Docker Engine e plugins..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2.7 Verifica instalação
if command -v docker &> /dev/null; then
    print_success "Docker instalado! Versão: $(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)"
else
    print_error "Falha na instalação do Docker."
    exit 1
fi

# ============================================
# PARTE 3: CONFIGURAÇÃO DE PERMISSÕES
# ============================================
print_message "Configurando permissões do Docker para o usuário atual..."

# Cria grupo docker se não existir (geralmente já é criado na instalação)
sudo groupadd -f docker

# Adiciona usuário ao grupo docker
sudo usermod -aG docker $USER

if [ $? -eq 0 ]; then
    print_success "Usuário $USER adicionado ao grupo docker!"
else
    print_error "Falha ao adicionar usuário ao grupo docker."
    exit 1
fi

# ============================================
# PARTE 4: TESTE BÁSICO
# ============================================
print_message "Testando instalação do Docker (com sudo)..."
sudo docker run hello-world || {
    print_warning "Teste com hello-world falhou. Verifique manualmente."
}

# ============================================
# MENSAGEM FINAL
# ============================================
echo ""
print_success "🎉 INSTALAÇÃO CONCLUÍDA!"
echo ""
print_warning "⚠️  PARA USAR DOCKER SEM SUDO:"
echo "   Opção 1: Faça logout e login novamente"
echo "   Opção 2: Execute este comando agora (temporário):"
echo "            newgrp docker"
echo ""
echo "📋 COMANDOS PARA TESTAR:"
echo "   gh --version"
echo "   docker --version"
echo "   docker compose version"
echo "   docker run hello-world   # após re-login ou newgrp"
echo ""
echo "💡 Configure o GitHub CLI: gh auth login"