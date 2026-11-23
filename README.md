# Detecção e mitigação de DoS/DDoS — Grupo 16

Laboratório isolado em Docker para executar ataques de negação de serviço contra um servidor web e medir o efeito das contramedidas. Todo o ambiente roda localmente, sem expor nada à internet.

## Arquitetura

O ambiente tem três containers numa rede privada (`labnet`):

| Container | Papel | Base |
|-----------|-------|------|
| `vitima`  | Servidor web atacado | Nginx |
| `atacante`| Dispara os ataques | ferramentas de rede (hping3, etc.) |
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

## Como derrubar o ambiente

```bash
docker compose down
```

## Métricas coletadas

- **Disponibilidade**: porcentagem de requisições respondidas com HTTP 200.
- **Tempo médio de resposta**: média do tempo total das requisições bem-sucedidas.
- **CPU da vítima**: uso de processador do container do servidor.
- **Conexões**: conexões TCP na porta 80 da vítima, separadas em `SYN-RECV` (meias-abertas, típicas de SYN flood) e `ESTABLISHED` (abertas, típicas de Slowloris).
