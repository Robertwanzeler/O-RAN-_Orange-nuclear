# Manual de Instalação: Ambiente de Simulação O-RAN

Versão: Orange Nuclear — ns-3 mmWave/O-RAN + FlexRIC  
Objetivo: instalar e validar um ambiente separado para instalação e debug.  
Data de referência: 03 de fevereiro de 2026.

> Este manual é documentação. Os comandos não são executados pelo Git de debug. Execute-os somente em um servidor, máquina virtual ou diretório de runtime autorizado.

## 0. Isolamento do runtime

Não use o checkout de outro projeto. Crie um diretório exclusivo:

```bash
export ORAN_DEBUG_ROOT="$HOME/orange_nuclear_debug_runtime"
mkdir -p "$ORAN_DEBUG_ROOT"
cd "$ORAN_DEBUG_ROOT"
```

Se já existir uma simulação em execução, não use `clean`, `docker rm`, `kill`, `pkill` ou `git checkout` no diretório dela.

## 1. Pré-requisitos

No Ubuntu/Linux autorizado:

```bash
sudo apt update
sudo apt install -y \
  git g++ cmake ninja-build build-essential \
  libgsl-dev libxml2-dev libsctp-dev \
  autoconf automake libtool libboost-all-dev \
  python3 python3-dev python3-pip \
  libsqlite3-dev libeigen3-dev gdb valgrind pkg-config
```

Verifique antes de continuar:

```bash
cd /caminho/para/orange_nuclear-debug
./scripts/check_environment.sh "$ORAN_DEBUG_ROOT"
```

## 2. Instalação do FlexRIC

```bash
cd "$ORAN_DEBUG_ROOT"
git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git flexric
cd flexric
git checkout oie-ric-taap-xapps
```

### 2.1 Correção de compilação

Esta versão mantém a pasta `examples`, necessária para gerar o RIC, e desativa a compilação dos xApps de exemplo que podem causar erros:

```bash
sed -i 's/# add_subdirectory(examples)/add_subdirectory(examples)/g' CMakeLists.txt
sed -i 's/add_subdirectory(xApp)/# add_subdirectory(xApp)/g' examples/CMakeLists.txt
```

Confirme as alterações antes do build:

```bash
git diff -- CMakeLists.txt examples/CMakeLists.txt
```

### 2.2 Build e instalação

```bash
cd "$ORAN_DEBUG_ROOT/flexric"
mkdir build
cd build
cmake .. \
  -DE2AP_VERSION=E2AP_V1 \
  -DKPM_VERSION=KPM_V3_00 \
  -G Ninja
ninja
sudo ninja install
sudo ldconfig
```

Valide o RIC:

```bash
test -x "$ORAN_DEBUG_ROOT/flexric/build/examples/ric/nearRT-RIC"
```

## 3. Instalação do ns-O-RAN/ns-3

```bash
cd "$ORAN_DEBUG_ROOT"
git clone https://github.com/Orange-OpenSource/ns-O-RAN-flexric.git ns-O-RAN-flexric
cd ns-O-RAN-flexric
git submodule update --init --recursive
```

Entre no simulador:

```bash
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran"
```

Configure o build com o módulo `energy`, obrigatório para os headers e modelos de energia utilizados pelo mmWave:

```bash
./ns3 clean
./ns3 configure \
  --disable-examples \
  --disable-tests \
  --enable-modules=nr,mmwave,oran-interface,lte,energy
```

Compile:

```bash
./ns3 build -j"$(nproc)"
```

Para um primeiro diagnóstico de compilação, prefira uma thread:

```bash
./ns3 build -j1
```

## 4. Execução da simulação

Use dois terminais dentro do mesmo runtime separado.

### Terminal 1 — FlexRIC

```bash
cd "$ORAN_DEBUG_ROOT/flexric/build/examples/ric"
./nearRT-RIC
```

Aguarde a inicialização do RIC e da conexão SCTP.

### Terminal 2 — ns-3

```bash
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran"
./ns3 run scratch/scenario-zero-with_parallel_loging
```

Não execute a simulação em um segundo checkout enquanto o primeiro runtime estiver usando portas, arquivos de saída ou processos compartilhados.

## 5. Checklist pós-instalação

```bash
./scripts/check_environment.sh "$ORAN_DEBUG_ROOT"
test -x "$ORAN_DEBUG_ROOT/flexric/build/examples/ric/nearRT-RIC"
test -x "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran/ns3"
git -C "$ORAN_DEBUG_ROOT/flexric" status --short
git -C "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric" submodule status
```

O status limpo não é obrigatório depois dos ajustes do CMake, mas as alterações devem estar restritas ao runtime separado.

## 6. Reset controlado

Não faça reset no ambiente em execução. Para reconstruir somente o runtime de debug, pare manualmente os processos desse runtime e então use um diretório novo:

```bash
export ORAN_DEBUG_ROOT="$HOME/orange_nuclear_debug_runtime_02"
mkdir -p "$ORAN_DEBUG_ROOT"
```

O checkout principal de outra simulação não deve ser usado como alvo de limpeza.
