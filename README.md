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
| `ids`     | Detecta os ataques (modo passivo) | Suricata |

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

Se você editar arquivos do projeto (ou trocar de branch no `git`) com os containers no ar, recrie-os para recarregar as versões novas:

```bash
docker compose up -d --force-recreate
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

## Ataque 2: Slowloris e mitigação no Nginx

O Slowloris abre muitas conexões com o servidor e envia requisições HTTP incompletas, bem devagar, sem nunca terminar. A vítima mantém cada conexão aberta esperando o resto da requisição; com conexões suficientes, esgota a capacidade e para de atender novos usuários. É um ataque de camada de aplicação: usa pouca banda e derruba o serviço. A ferramenta é um script Python próprio (`ataques/slowloris.py`), no container `atacante`.

A defesa são ajustes no Nginx (`vitima/conf/defesa.conf`, aplicados pelo `defesa/nginx.sh`): timeouts curtos de leitura da requisição (`client_header_timeout` e `client_body_timeout`), que fecham conexões lentas antes que se acumulem; capacidade adequada (`worker_connections`); e limites por origem (`limit_conn`, `limit_req`).

Experimento completo:

```bash
bash experimentos/slowloris.sh
```

Comandos individuais:

```bash
bash ataques/atacar_slowloris.sh 300 60
```

```bash
bash defesa/nginx.sh on
```

```bash
bash defesa/nginx.sh off
```

O ataque leva a disponibilidade a 0% (servidor fora do ar) e lota as conexões `ESTABLISHED`; com a defesa, a disponibilidade volta a 100% e as conexões ficam sob controle.

Observação importante: o `limit_conn` sozinho não detém o Slowloris, porque a requisição nunca se completa e não chega à fase em que o limite é aplicado. Quem neutraliza o ataque é o timeout curto, que fecha as conexões lentas. Nos testes, só o timeout curto (com `worker_connections` baixo) já recuperou a disponibilidade de 0% para cerca de 77%; combinado com capacidade adequada, chegou a 100%.

## Detecção com IDS (Suricata)

Além de mitigar, o laboratório detecta os ataques com um IDS. O container `ids` roda o Suricata compartilhando a rede da vítima e observando todo o tráfego que chega a ela, em modo passivo (apenas alerta, não bloqueia). As regras estão em `ids/regras.rules`:

- uma detecta o **SYN flood** pela alta taxa de pacotes SYN chegando à vítima;
- outra detecta o **Slowloris** pela quantidade de conexões abertas por uma única origem.

Rodar os dois ataques e ver os alertas:

```bash
bash experimentos/ids.sh
```

Os alertas aparecem em `ids/logs/fast.log`, identificando o tipo de ataque, a origem e o alvo. Observação: como o nosso SYN flood usa uma única origem forjada, ele também dispara a regra de "muitas conexões de uma origem" — na prática as regras de um IDS costumam se sobrepor assim.

## Resumo dos resultados

| Cenário | Disponibilidade | Tempo médio | Conexões na vítima |
|---------|-----------------|-------------|--------------------|
| Baseline | 100% | ~2 ms | 0 |
| SYN flood sem defesa | 100% | sobe | ~150 `SYN-RECV` |
| SYN flood com firewall | 100% | normal | 0 |
| Slowloris sem defesa | 0% | — | ~62 `ESTABLISHED` |
| Slowloris com defesa | 100% | ~2 ms | controlado |

Os números exatos de cada execução ficam em `resultados/resultados.csv`. O SYN flood não zera a disponibilidade por causa da limitação do ambiente (ver seção do ataque 1); o Slowloris, de camada de aplicação, derruba o serviço por completo.

## Como derrubar o ambiente

```bash
docker compose down
```

## Métricas coletadas

- **Disponibilidade**: porcentagem de requisições respondidas com HTTP 200.
- **Tempo médio de resposta**: média do tempo total das requisições bem-sucedidas.
- **CPU da vítima**: uso de processador do container do servidor.
- **Conexões**: conexões TCP na porta 80 da vítima, separadas em `SYN-RECV` (meias-abertas, típicas de SYN flood) e `ESTABLISHED` (abertas, típicas de Slowloris).
