# Guia de Debug: ns-3 + FlexRIC/O-RAN

Todos os exemplos usam o runtime isolado definido em `ORAN_DEBUG_ROOT`. O Git de debug não inicia serviços nem altera o ambiente.

## 1. Diagnóstico inicial

```bash
./scripts/check_environment.sh "$ORAN_DEBUG_ROOT"
```

Verifique versões:

```bash
git --version
g++ --version
cmake --version
ninja --version
```

Verifique os fontes:

```bash
git -C "$ORAN_DEBUG_ROOT/flexric" status --short
git -C "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric" status --short
git -C "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric" submodule status
```

## 2. Debug de compilação do ns-3

Configure em modo de desenvolvimento e compile com uma thread:

```bash
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran"
./ns3 clean
./ns3 configure \
  --disable-examples \
  --disable-tests \
  --enable-modules=nr,mmwave,oran-interface,lte,energy
./ns3 build -j1
```

Se houver erro de módulo ou header:

```bash
./ns3 show config
./ns3 show targets
rg -n "energy|mmwave|oran-interface" build cmake-cache src contrib 2>/dev/null
```

O erro `ns3/energy-model-helper.h: No such file` normalmente indica que `energy` não foi incluído em `--enable-modules` ou que o build está usando outro checkout.

## 3. GDB

O wrapper do ns-3 pode iniciar o programa pelo GDB:

```bash
./ns3 run scratch/scenario-zero-with_parallel_loging --gdb
```

Comandos essenciais:

```gdb
break main
run
next
step
backtrace
info locals
print nome_da_variavel
continue
quit
```

Para um binário específico, localize o alvo com `./ns3 show targets` e use `gdb --args` somente no runtime isolado.

## 4. Valgrind

```bash
./ns3 run scratch/scenario-zero-with_parallel_loging --valgrind
```

Para gravar um relatório:

```bash
valgrind \
  --leak-check=full \
  --show-leak-kinds=all \
  --track-origins=yes \
  --log-file=valgrind-ns3.txt \
  ./ns3 run scratch/scenario-zero-with_parallel_loging
```

Os arquivos de saída devem permanecer no runtime de debug, nunca no checkout principal.

## 5. Logs do ns-3

```bash
NS_LOG='Simulator=level_all|prefix_time' \
  ./ns3 run scratch/scenario-zero-with_parallel_loging
```

Para salvar a saída:

```bash
NS_LOG='level_info|prefix_time' \
  ./ns3 run scratch/scenario-zero-with_parallel_loging \
  > ns3-simulation.log 2>&1
```

Procure erros:

```bash
rg -ni 'error|fatal|warning|assert|exception|sctp|refused' ns3-simulation.log
```

## 6. Debug do FlexRIC

Verifique o binário antes de iniciar:

```bash
test -x "$ORAN_DEBUG_ROOT/flexric/build/examples/ric/nearRT-RIC"
ldd "$ORAN_DEBUG_ROOT/flexric/build/examples/ric/nearRT-RIC"
```

Inicie o RIC em um terminal e observe suas mensagens. Em outro terminal, execute o ns-3. Não use `sudo`, `kill`, `pkill` ou `docker rm` para resolver uma falha sem identificar primeiro o processo pertencente ao runtime de debug.

## 7. Problemas comuns

### `add_subdirectory(xApp)`

Confira se os ajustes do CMake foram aplicados dentro do clone isolado do FlexRIC:

```bash
cd "$ORAN_DEBUG_ROOT/flexric"
git diff -- CMakeLists.txt examples/CMakeLists.txt
```

Depois, reconfigure o build do FlexRIC no mesmo runtime.

### `ns3/energy-model-helper.h: No such file`

Reconfigure o ns-3 incluindo `energy`:

```bash
./ns3 clean
./ns3 configure \
  --disable-examples \
  --disable-tests \
  --enable-modules=nr,mmwave,oran-interface,lte,energy
./ns3 build -j1
```

### `Connection refused`

Verifique, sem alterar processos:

```bash
test -x "$ORAN_DEBUG_ROOT/flexric/build/examples/ric/nearRT-RIC"
pgrep -af nearRT-RIC || true
ss -ltnp 2>/dev/null || true
```

Se o RIC não estiver em execução, inicie-o no Terminal 1. Se houver outro serviço usando a porta necessária, use um runtime/servidor separado em vez de interromper o serviço existente.

### Submódulo vazio

```bash
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric"
git submodule update --init --recursive
git submodule status
```

### Build inconsistente após alterações

Faça limpeza somente no runtime isolado:

```bash
cd "$ORAN_DEBUG_ROOT/ns-O-RAN-flexric/mmwave-LENA-oran"
./ns3 clean
./ns3 configure \
  --disable-examples \
  --disable-tests \
  --enable-modules=nr,mmwave,oran-interface,lte,energy
./ns3 build -j1
```
