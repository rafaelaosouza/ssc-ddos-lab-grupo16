# Detecção e mitigação de DoS/DDoS
# Grupo 16

Laboratório isolado em Docker para executar ataques de negação de serviço contra um servidor web e medir o efeito das contramedidas. Todo o ambiente roda localmente, sem expor nada à internet.

## Arquitetura

O ambiente tem três containers numa rede privada (`labnet`):

| Container | Papel | Base |
|-----------|-------|------|
| `vitima`  | Servidor web atacado | Nginx |
| `atacante`| Dispara os ataques | Debian com `hping3` e `python3` |
| `cliente` | Simula um usuário legítimo e coleta as métricas | curl |

A ideia do laboratório: o `cliente` mede como o servidor responde em três situações — sem ataque (baseline), sob ataque sem defesa, e sob ataque com a defesa ativa.

## Pré-requisitos

- Docker e Docker Compose (Docker Desktop, Colima ou Docker Engine)

## Como subir o ambiente

```bash
docker compose up -d
```

Verifique se os três containers estão de pé:

```bash
docker compose ps
```

## Como medir

O script `medicao/medir.sh` envia uma sequência de requisições do `cliente` para a `vitima` e imprime quatro métricas: disponibilidade, tempo médio de resposta, uso de CPU da vítima e número de conexões TCP abertas.

```bash
bash medicao/medir.sh baseline
```

O primeiro argumento é o nome do cenário (aparece na saída) e o segundo, opcional, é a quantidade de requisições (padrão 50):

```bash
bash medicao/medir.sh baseline 100
```

Cada medição também é gravada em `resultados/resultados.csv`, que serve de base para gerar os gráficos de comparação do relatório.

## Ataque 1: SYN flood e mitigação com firewall

O SYN flood envia uma enxurrada de pacotes TCP SYN com endereço de origem forjado e nunca completa a conexão. A vítima guarda cada conexão meia-aberta (estado `SYN-RECV`) à espera de uma resposta que não chega, consumindo espaço na fila de conexões. A ferramenta é o `hping3`, no container `atacante`.

A defesa é um firewall `nftables` na vítima (`vitima/firewall.nft`) que limita a taxa de novas conexões por endereço de origem. O excesso vindo do atacante é descartado antes de criar estado no servidor.

Experimento completo (mede os três cenários e grava no CSV):

```bash
bash experimentos/syn_flood.sh
```

Comandos individuais:

```bash
bash ataques/atacar_syn.sh 20
```

```bash
bash defesa/firewall.sh on
```

```bash
bash defesa/firewall.sh off
```

O ataque faz o `SYN-RECV` saltar de 0 para mais de uma centena e o tempo de resposta subir; com o firewall ativo, as meia-abertas voltam a 0 e o tempo normaliza.

A vítima roda com SYN cookies desativados e `rp_filter` desligado (em `docker-compose.yml`) para que as conexões meia-abertas forjadas fiquem visíveis. No Docker Desktop em macOS a camada de rede virtualizada limita a taxa real do flood, então o ataque não zera a disponibilidade: o efeito mensurável é o acúmulo de `SYN-RECV` e o aumento de latência, que o firewall elimina. Como o limite é por origem, ele neutraliza um atacante de origem única; um ataque realmente distribuído exigiria defesas adicionais, como SYN cookies.

## Como derrubar o ambiente

```bash
docker compose down
```

## Métricas coletadas

- **Disponibilidade**: porcentagem de requisições respondidas com HTTP 200.
- **Tempo médio de resposta**: média do tempo total das requisições bem-sucedidas.
- **CPU da vítima**: uso de processador do container do servidor.
- **Conexões**: conexões TCP na porta 80 da vítima, separadas em `SYN-RECV` (meias-abertas, típicas de SYN flood) e `ESTABLISHED` (abertas, típicas de Slowloris).
