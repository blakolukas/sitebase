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
    echo "  --skip-install             INICIA os ambientes ignorando as etapas de instalação, executando diretamente make start e VS Code"
	echo "  --shutdown                 DESLIGA os ambientes caso eles tenham sido iniciados por este setup"
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
		--shutdown) shutdown_local_environments ;;
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
		cd $repo_ref
		pwd
		
		echo "Efetuando checkout da branch..."
		git checkout "$repo_branch"
		checkErrors
		
		echo "Efetuando Pull..."
		git pull
		checkErrors
    else
        git clone -b "$repo_branch" "$repo_url" "$repo_ref"
		cd $repo_ref
		pwd
    fi
}

# Função para desligar ambientes locais que foram iniciados por este setup
shutdown_local_environments() {
    if [[ -f "backend.pid" ]]; then
        kill -9 $(cat backend.pid) && rm backend.pid
        echo "Backend encerrado."
    else
        echo "Backend já está desligado ou PID não encontrado."
    fi

    if [[ -f "frontend.pid" ]]; then
        kill -9 $(cat frontend.pid) && rm frontend.pid
        echo "Frontend encerrado."
    else
        echo "Frontend já está desligado ou PID não encontrado."
    fi
    exit 0
}

# Função para instalar prerequisitos 
install_and_update_prerequisites() {
	echo "Verificando antes de iniciar a instalação..."
	if ! command -v make &> /dev/null; then
		echo "Make não encontrado. Iniciando Upgrade geral e Instalando dependencias..."
		
		sudo apt update -y
		sudo apt upgrade -y
		apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
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

    # Verificação e execução de instalação no backend, se necessário
    if [[ "$SKIP_INSTALL" = false ]]; then
		install_and_update_prerequisites
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
            curl https://pyenv.run | bash
			echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
			echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
			echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bashrc
			source ~/.bashrc
        else
            echo "Pyenv já está instalado."
        fi
		if ! command -v pipx &> /dev/null; then
            echo "pipx não encontrado. Instalando pipx..."
            # sudo apt update && sudo apt install -y python3
            pip install pipx
        else
            echo "pipx já está instalado."
        fi
        make install
    fi

    # Abrir VS Code para o backend
    code .

    # Iniciar o backend em segundo plano
    echo "Iniciando o backend em modo detached..."
    nohup make start > backend.log 2>&1 &
	echo $! > backend.pid
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
	echo $! > frontend.pid
fi

echo "Script concluído! Logs de backend e frontend estão em backend.log e frontend.log na raíz de cada projeto, caso tenham sido iniciados."
