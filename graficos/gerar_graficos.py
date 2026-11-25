import matplotlib.pyplot as plt

cinza = "#6b7280"
vermelho = "#c0392b"
verde = "#2e7d32"


def grafico_barras(titulo, rotulos, valores, cores, eixo_y, arquivo):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    barras = ax.bar(rotulos, valores, color=cores, width=0.6)
    ax.set_title(titulo, fontsize=16, fontweight="bold", pad=16)
    ax.set_ylabel(eixo_y, fontsize=12)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.tick_params(labelsize=12)
    topo = max(valores) if max(valores) > 0 else 1
    ax.set_ylim(0, topo * 1.2)
    for barra, valor in zip(barras, valores):
        ax.text(
            barra.get_x() + barra.get_width() / 2,
            valor + topo * 0.02,
            str(valor),
            ha="center",
            va="bottom",
            fontsize=14,
            fontweight="bold",
        )
    fig.tight_layout()
    fig.savefig(arquivo, dpi=200, transparent=True)
    plt.close(fig)


grafico_barras(
    "Slowloris: disponibilidade do servidor",
    ["Normal", "Sob ataque", "Com defesa"],
    [100, 0, 100],
    [cinza, vermelho, verde],
    "Disponibilidade (%)",
    "slowloris_disponibilidade.png",
)

grafico_barras(
    "SYN flood: conexoes meia-abertas na vitima",
    ["Normal", "Sob ataque", "Com firewall"],
    [0, 149, 0],
    [cinza, vermelho, verde],
    "Conexoes SYN-RECV",
    "syn_flood_conexoes.png",
)

print("Gerados: slowloris_disponibilidade.png e syn_flood_conexoes.png")
