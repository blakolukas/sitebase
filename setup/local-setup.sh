#!/bin/bash

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 BACKEND_REPO_URL FRONTEND_REPO_URL [opções]"
    echo
    echo "Parâmetros:"
    echo "  BACKEND_REPO_URL           URL do repositório do backend (obrigatório)"
    echo "  FRONTEND_REPO_URL          URL do repositório do frontend (obrigatório)"
    echo
    echo "Opções:"
    echo "  --backend-ref PATH         Define o diretório de referência para o backend (opcional)"
    echo "  --frontend-ref PATH        Define o diretório de referência para o frontend (opcional)"
    echo "  --backend-branch BRANCH    Define a branch do repositório backend (padrão: main)"
    echo "  --frontend-branch BRANCH   Define a branch do repositório frontend (padrão: main)"
    echo "  --skip-install             Ignora as etapas de instalação e executa diretamente make start e VS Code"
    echo "  --help                     Exibe esta ajuda"
    exit 0
}

# Verifica se o usuário solicitou ajuda
if [[ "$1" == "--help" ]]; then
    show_help
fi

# Parâmetros obrigatórios para o repositório backend e frontend
BACKEND_REPO_URL=$1
FRONTEND_REPO_URL=$2

# Parâmetros opcionais --ref, --branch, e --skip-install
BACKEND_REF=""
FRONTEND_REF=""
BACKEND_BRANCH="main"
FRONTEND_BRANCH="main"
SKIP_INSTALL=false

# Parsing de parâmetros
shift 2
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --backend-ref) BACKEND_REF="$2"; shift ;;
        --frontend-ref) FRONTEND_REF="$2"; shift ;;
        --backend-branch) BACKEND_BRANCH="$2"; shift ;;
        --frontend-branch) FRONTEND_BRANCH="$2"; shift ;;
        --skip-install) SKIP_INSTALL=true ;;
        --help) show_help ;;
        *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Função para checar erros e abortar execução
function checkErrors {
    if [ $? -ne 0 ]; then
        echo "Erro encontrado, abortando script..."
        exit 1
    fi
}

# Função para clonar repositório se a pasta não existir
clone_repo() {
    local repo_url=$1
    local repo_ref=$2
    local repo_branch=$3

    if [[ -d "$repo_ref" ]]; then
        echo "Repositório já clonado em $repo_ref. Pulando clone."
		
		echo "Efetuando checkout da branch..."
		git checkout "$repo_url"
		checkErrors
		
		echo "Efetuando Pull..."
		git pull
		checkErrors
    else
        git clone -b "$repo_branch" "$repo_url" "$repo_ref"
    fi
}

install_and_update_make() {
	echo "Verificando antes de iniciar a instalação..."
	if ! command -v make &> /dev/null; then
		echo "Make não encontrado. Iniciando Upgrade geral e Instalando Make..."
		
		sudo apt update
		sudo apt upgrade
		sudo apt install make
	else
		echo "Make já está instalado."
	fi
}

# Verificar se o URL do repositório backend foi fornecido
if [[ -z "$BACKEND_REPO_URL" ]]; then
    echo "Aviso: O parâmetro BACKEND_REPO_URL não foi fornecido. Pulando instalação e inicialização do backend. Adicione --help para ver a lista completa de parâmetros."
else
    echo "-----> Iniciando instalação do Backend"
	# Clone do repositório backend
    BACKEND_DIR=${BACKEND_REF:-$(basename "$BACKEND_REPO_URL" .git)}
    clone_repo "$BACKEND_REPO_URL" "$BACKEND_DIR" "$BACKEND_BRANCH"
    cd "$BACKEND_DIR"

    # Verificação e execução de instalação no backend, se necessário
    if [[ "$SKIP_INSTALL" = false ]]; then
		install_and_update_make
        if ! command -v python3 &> /dev/null; then
            echo "Python 3 não encontrado. Instalando Python 3..."
            # sudo apt update && sudo apt install -y python3
            sudo apt install -y python3
        else
            echo "Python 3 já está instalado."
        fi
		if ! command -v pyenv &> /dev/null; then
            echo "Pyenv não encontrado. Instalando Pyenv..."
            # sudo apt update && sudo apt install -y python3
            sudo apt install -y pyenv
        else
            echo "Pyenv já está instalado."
        fi
        make install
    fi

    # Abrir VS Code para o backend
    code .

    # Iniciar o backend em segundo plano
    echo "Iniciando o backend em modo detached..."
    nohup make start > backend.log 2>&1 &
    cd ..
fi

# Verificar se o URL do repositório frontend foi fornecido
if [[ -z "$FRONTEND_REPO_URL" ]]; then
    echo "Aviso: O parâmetro FRONTEND_REPO_URL não foi fornecido. Pulando instalação e inicialização do frontend. Adicione --help para ver a lista completa de parametros."
else
	echo "-----> Iniciando instalação do Frontend"
    # Clone do repositório frontend
    FRONTEND_DIR=${FRONTEND_REF:-$(basename "$FRONTEND_REPO_URL" .git)}
    clone_repo "$FRONTEND_REPO_URL" "$FRONTEND_DIR" "$FRONTEND_BRANCH"
    cd "$FRONTEND_DIR"

    # Verificação e execução de instalação no frontend, se necessário
    if [[ "$SKIP_INSTALL" = false ]]; then
		if ! command -v nvm &> /dev/null; then
            echo "NVM não encontrado. Instalando NVM..."
            # sudo apt update && sudo apt install -y python3
			curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
            source ~/.bashrc
        else
            echo "NVM já está instalado."
        fi
		if ! command -v node &> /dev/null; then
            echo "Node não encontrado. Instalando Node..."
            # sudo apt update && sudo apt install -y python3
            # sudo apt install -y node
			nvm install lts/iron
        else
            echo "Node já está instalado."
        fi
        if ! command -v pnpm &> /dev/null; then
            echo "PNPM não encontrado. Instalando pnpm..."
            # curl -fsSL https://get.pnpm.io/install.sh | sh -
            npm install -g pnpm
        else
            echo "PNPM já está instalado."
        fi
        pnpm install
        make install
		
		git restore pnpm-lock.yaml
    fi

    # Abrir VS Code para o frontend
    code .

    # Iniciar o frontend em segundo plano
    echo "Iniciando o frontend em modo detached..."
    nohup make start > frontend.log 2>&1 &
fi

echo "Script concluído! Logs de backend e frontend estão em backend.log e frontend.log na raíz de cada projeto, caso tenham sido iniciados."