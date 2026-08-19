# Orange Nuclear Debug Guide

Repositório separado para documentar a instalação e o debug do ambiente ns-3 com mmWave/O-RAN e FlexRIC.

Este repositório não contém o código-fonte do simulador, resultados, modelos ou credenciais. Ele também não altera o ambiente existente em `/home/robert/orange_nuclear`.

## Documentos

- [Manual de instalação](MANUAL_INSTALACAO_ORAN.md)
- [Guia de debug](GUIA_DEBUG_NS3_FLEXRIC.md)

## Scripts seguros

Os scripts deste repositório são somente leitura por padrão:

```bash
./scripts/check_environment.sh
./scripts/check_environment.sh "$HOME/orange_nuclear_debug_runtime"
./scripts/show_install_commands.sh
```

Eles não executam `apt`, `sudo`, `git clone`, `sed`, `cmake`, `make`, nem iniciam ou param processos. Os comandos de instalação são apenas impressos para execução manual em um servidor ou ambiente isolado escolhido pelo operador.

## Runtime recomendado

Use um diretório separado para os fontes e builds:

```text
$HOME/orange_nuclear_debug_runtime/
├── flexric/
└── ns-O-RAN-flexric/
```

O runtime não deve ser o checkout da simulação já existente.
