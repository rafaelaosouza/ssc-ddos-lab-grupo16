# Diagramas do laboratório

Estes diagramas usam Mermaid. Eles renderizam automaticamente no GitHub e no VS Code (com a extensão Mermaid). Para virar imagem de slide, abra em https://mermaid.live, cole o bloco e exporte como PNG.

## 1. Arquitetura do laboratório

```mermaid
flowchart LR
    subgraph labnet["Rede isolada (labnet)"]
        atacante["atacante<br/>hping3 / Slowloris"]
        cliente["cliente<br/>curl (mede)"]
        vitima["vitima<br/>Nginx + firewall"]
        ids["ids<br/>Suricata"]
    end
    atacante -->|ataca| vitima
    cliente -->|requisicoes| vitima
    ids -.->|observa o trafego| vitima
```

## 2. SYN flood (ataque de rede)

```mermaid
sequenceDiagram
    participant A as Atacante
    participant V as Vitima
    A->>V: SYN (passo 1)
    V->>A: SYN-ACK (passo 2)
    Note over A,V: o passo 3 (ACK) nunca chega
    Note over V: a conexao fica meia-aberta e ocupa a fila
```

## 3. Slowloris (ataque de aplicacao)

```mermaid
sequenceDiagram
    participant A as Atacante
    participant V as Vitima
    A->>V: GET / HTTP/1.1 (cabecalho incompleto)
    loop a cada 10 segundos
        A->>V: envia so mais uma linha, sem terminar
    end
    Note over V: dezenas de conexoes presas abertas esgotam a capacidade
```
