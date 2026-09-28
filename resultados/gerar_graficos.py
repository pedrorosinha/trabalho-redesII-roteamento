import csv
import matplotlib.pyplot as plt

arquivo = "tamanho_rotas.csv"

dados = {}

with open(arquivo, newline="") as f:
    reader = csv.DictReader(f)

    for row in reader:
        protocolo = row["protocolo"]
        roteador = row["roteador"]
        rotas = int(row["rotas"])

        dados.setdefault(protocolo, {})[roteador] = rotas

roteadores = ["r1", "r2", "r3", "r4", "r5"]
protocolos = ["OSPF", "RIP", "BGP"]

for protocolo in protocolos:

    valores = [
        dados.get(protocolo, {}).get(r, 0)
        for r in roteadores
    ]

    plt.figure(figsize=(8, 5))

    plt.bar(
        roteadores,
        valores
    )

    plt.title(
        f"Tamanho da tabela de rotas - {protocolo}"
    )

    plt.xlabel("Roteador")
    plt.ylabel("Quantidade de rotas")

    plt.tight_layout()

    plt.savefig(
        f"grafico_rotas_{protocolo.lower()}.png",
        dpi=150
    )

    plt.close()

plt.figure(figsize=(9, 5))

largura = 0.25

for i, protocolo in enumerate(protocolos):

    valores = [
        dados.get(protocolo, {}).get(r, 0)
        for r in roteadores
    ]

    posicoes = [
        j + (i - 1) * largura
        for j in range(len(roteadores))
    ]

    plt.bar(
        posicoes,
        valores,
        width=largura,
        label=protocolo
    )

plt.xticks(
    range(len(roteadores)),
    roteadores
)

plt.xlabel("Roteador")
plt.ylabel("Quantidade de rotas")

plt.title(
    "Comparação do tamanho das tabelas de roteamento"
)

plt.legend()

plt.tight_layout()

plt.savefig(
    "grafico_comparacao_rotas.png",
    dpi=150
)

plt.close()

print("Gráficos gerados com sucesso.")
