# Roteiro dos slides (11 slides, ~10 min)

Regras gerais:
- Uma ideia e um visual por slide. Texto curto; o visual fala.
- Sem IPs nos slides (corte dos prints). IPs só no relatório.
- "No slide" = o que aparece. "Fala" = o que você diz (pode colar nas notas do apresentador).
- Imagens: gráficos em `graficos/` (depois de rodar o script), diagramas em `docs/diagramas.md`.

---

## 1. Capa
**No slide:** (já pronta) título + Rafaela Oliveira de Souza + 202365133C + Grupo 16 + disciplina.
**Fala:** "Oi, sou a Rafaela. Vou falar sobre ataques de negação de serviço: como funcionam, como se defender e como detectá-los."

## 2. Sumário
**No slide:**
- O que é DoS/DDoS e o laboratório
- Ataque 1: SYN flood e firewall
- Ataque 2: Slowloris e ajuste no servidor
- Detecção com IDS
- Conclusões

**Fala:** "Vou seguir esta ordem: o conceito e o laboratório, os dois ataques com suas defesas, a detecção, e as conclusões."

## 3. O que é DoS/DDoS?
**No slide:**
- Tornar um serviço indisponível para os usuários legítimos
- Analogia: ocupar todas as mesas de um restaurante para clientes de verdade não sentarem

**Visual:** desenho do restaurante (mesas ocupadas, cliente barrado na porta).
**Fala:** "DoS é deixar um serviço fora do ar pros usuários de verdade — como alguém que ocupa todas as mesas de um restaurante de propósito. DoS é um atacante; DDoS é um exército distribuído, de muitas origens. Vou mostrar dois tipos de ataque e como defender."

## 4. O laboratório
**No slide:**
- Ambiente isolado em Docker, 100% local (atacar um servidor real seria crime)
- Medimos 3 coisas: disponibilidade, tempo de resposta, conexões
- Em 3 cenários: normal, sob ataque, com defesa

**Visual:** diagrama da arquitetura (`docs/diagramas.md`, diagrama 1).
**Fala:** "Montei um laboratório fechado no meu computador com Docker: a vítima, que é o servidor; o atacante; um cliente que mede; e um detector. Pra cada ataque meço disponibilidade, tempo e conexões, em três situações: normal, sob ataque e com defesa."

## 5. SYN flood — como funciona
**No slide:**
- Manda milhares de pedidos de conexão e nunca os completa
- O servidor guarda cada conexão "meia-aberta" esperando — e a fila enche

**Visual:** diagrama do handshake (`docs/diagramas.md`, diagrama 2).
**Fala:** "Para abrir uma conexão são 3 passos. No SYN flood, o atacante manda o passo 1 aos milhares e nunca responde o passo 3. O servidor fica com um monte de conexões pela metade — como mil reservas falsas que ninguém aparece para usar."

## 6. SYN flood — resultado e defesa
**No slide:**
- Conexões meia-abertas: 0 → ~150 → 0
- Defesa: firewall (nftables) limita conexões novas por origem

**Visual:** gráfico `graficos/syn_flood_conexoes.png`.
**Fala:** "Sem defesa, as conexões meia-abertas disparam; com o firewall, voltam a zero — é o porteiro que limita reservas por telefone. Uma observação honesta: no Docker em Mac o ambiente limitou a força do ataque, então a disponibilidade não chegou a cair; registrei isso como limitação."

## 7. Slowloris — como funciona
**No slide:**
- Abre muitas conexões e envia a requisição devagar, sem terminar
- Segura o servidor aberto com pouquíssima banda

**Visual:** diagrama das conexões presas (`docs/diagramas.md`, diagrama 3).
**Fala:** "O Slowloris é o oposto: usa lentidão. Abre várias conexões e envia a requisição pingo a pingo, sem terminar. O servidor segura todas abertas esperando — como clientes que pedem devagar e nunca terminam, travando os garçons."

## 8. Slowloris — resultado e defesa
**No slide:**
- Disponibilidade: 100% → 0% → 100%
- Defesa: ajustes no Nginx (timeouts curtos fecham conexões lentas)

**Visual:** gráfico `graficos/slowloris_disponibilidade.png`.
**Fala:** "Aqui o ataque derrubou o site a zero. A defesa é o garçom que desiste de quem demora demais — timeouts curtos no servidor. A disponibilidade voltou a 100%. Descobri que limitar conexões sozinho não segura o Slowloris; o que resolve é o timeout curto."

## 9. Detecção (IDS)
**No slide:**
- Um detector observa o tráfego e alerta quando reconhece um ataque
- O Suricata gerou alertas para os dois ataques

**Visual:** print do alerta do Suricata (`ids/logs/fast.log`) — com os IPs apagados.
**Fala:** "Além de defender, dá pra detectar: o Suricata vigia o tráfego da vítima e, com regras, reconhece os dois ataques e gera alertas. É a câmera de segurança do restaurante."

## 10. Conclusões
**No slide:**
- Ataque de rede → defesa no firewall
- Ataque de aplicação → ajuste no servidor web
- O IDS detecta os dois → defesa em camadas
- Próximos passos: testar DDoS real e o IDS em modo de bloqueio (IPS)

**Fala:** "O principal aprendizado: não existe defesa única. O ataque de rede se resolve no firewall; o de aplicação, ajustando o servidor; e o IDS complementa, detectando os dois. Cada camada tem seu ataque e sua defesa."

## 11. Referências
**No slide:** (já pronta) Nginx, nftables, Suricata, hping3, OWASP.
**Fala:** "Essas foram as referências. Obrigada! Posso responder perguntas."
