# Métricas dos Protocolos de Roteamento

Este diretório contém os resultados dos experimentos realizados com os protocolos **OSPF, RIP e BGP** na topologia de cinco roteadores utilizando FRRouting (FRR) em containers Docker.

Os protocolos foram executados **separadamente**, utilizando a mesma topologia física, permitindo comparar seus comportamentos em condições equivalentes.

## 1. Objetivo

As métricas coletadas têm como objetivo analisar:

* tamanho das tabelas de roteamento;
* conectividade entre os roteadores;
* atraso médio da comunicação;
* perda de pacotes;
* informações de vizinhança;
* informações de controle do BGP;
* comportamento diante de uma alteração na topologia;
* utilização de recursos computacionais.

---

## 2. Topologia utilizada

A topologia possui cinco roteadores:

```text
             AS 100
        R1 ---------- R2
        |              |
        |              |
        R3 ---------- R4
         \              /
          \            /
             R5
             AS 300

R3 e R4 pertencem ao AS 200.
```

### Sistemas Autônomos

| Roteador |  AS |
| -------- | --: |
| R1       | 100 |
| R2       | 100 |
| R3       | 200 |
| R4       | 200 |
| R5       | 300 |

### Enlaces

| Enlace  | Rede         |
| ------- | ------------ |
| R1 - R2 | 10.0.12.0/30 |
| R1 - R3 | 10.0.13.0/30 |
| R2 - R4 | 10.0.24.0/30 |
| R3 - R4 | 10.0.34.0/30 |
| R3 - R5 | 10.0.35.0/30 |
| R4 - R5 | 10.0.45.0/30 |

---

## 3. Protocolos avaliados

Foram avaliados três protocolos:

* **OSPF** — protocolo de roteamento interno baseado em estado de enlace;
* **RIP** — protocolo de vetor de distância;
* **BGP** — protocolo utilizado para roteamento entre Sistemas Autônomos.

Os protocolos não foram executados simultaneamente. Para cada experimento, o laboratório foi destruído e recriado utilizando exclusivamente a configuração do protocolo analisado.

---

# 4. Tamanho das tabelas de roteamento

A quantidade de entradas observadas foi:

| Protocolo | R1 | R2 | R3 | R4 | R5 |
| --------- | -: | -: | -: | -: | -: |
| OSPF      | 16 | 16 | 17 | 17 | 16 |
| RIP       | 13 | 13 | 13 | 13 | 13 |
| BGP       | 10 |  9 | 10 | 10 | 10 |

### Observação

Os valores representam a quantidade de rotas apresentada pela tabela de roteamento do FRR durante o experimento.

A quantidade de entradas não deve ser utilizada isoladamente para determinar qual protocolo possui melhor desempenho, pois cada protocolo possui mecanismos diferentes de descoberta, seleção e manutenção de rotas.

O arquivo correspondente é:

```text
tamanho_rotas.csv
```

---

# 5. Conectividade

Foi realizado um teste de conectividade entre:

```text
R1 → R5
```

utilizando o endereço:

```text
192.168.50.1
```

Foram enviados 10 pacotes ICMP em cada experimento.

## Resultados

| Protocolo | Pacotes enviados | Pacotes recebidos | Perda |
| --------- | ---------------: | ----------------: | ----: |
| OSPF      |               10 |                10 |    0% |
| RIP       |               10 |                10 |    0% |
| BGP       |               10 |                10 |    0% |

Os três protocolos permitiram comunicação entre R1 e R5 durante os testes realizados.

Arquivos:

```text
ping_OSPF.txt
ping_RIP.txt
ping_BGP.txt
```

---

# 6. RTT (Round-Trip Time)

O tempo de ida e volta dos pacotes ICMP foi utilizado como uma medida de atraso no ambiente experimental.

| Protocolo |   Mínimo |    Médio |   Máximo |
| --------- | -------: | -------: | -------: |
| OSPF      | 0,060 ms | 0,125 ms | 0,253 ms |
| RIP       | 0,056 ms | 0,120 ms | 0,202 ms |
| BGP       | 0,064 ms | 0,159 ms | 0,277 ms |

Os valores foram obtidos a partir dos testes de ping realizados entre R1 e R5.

Como os experimentos foram executados em containers no mesmo ambiente físico, os valores de RTT representam principalmente as condições do laboratório. Eles não devem ser interpretados como uma comparação geral do atraso desses protocolos em redes reais.

---

# 7. BGP

Para o BGP foi coletado o resultado do comando:

```bash
show ip bgp summary
```

No R1, foram observados dois vizinhos BGP:

| Vizinho   |  AS | Prefixos recebidos |
| --------- | --: | -----------------: |
| 10.0.12.2 | 100 |                  4 |
| 10.0.13.2 | 200 |                  3 |

As duas sessões encontravam-se estabelecidas.

Também foram observados:

```text
RIB entries: 9
Peers: 2
```

Os dados completos estão disponíveis em:

```text
bgp_summary.txt
```

---

# 8. Mensagens BGP

O resumo do BGP também permite observar a quantidade de mensagens recebidas e enviadas pelos vizinhos.

No R1:

| Vizinho   | Mensagens recebidas | Mensagens enviadas |
| --------- | ------------------: | -----------------: |
| 10.0.12.2 |                   7 |                  7 |
| 10.0.13.2 |                   8 |                  7 |

Esses valores representam mensagens do protocolo BGP trocadas entre os peers durante o período observado.

Eles não representam a quantidade total de pacotes transmitidos pela rede.

Para obter uma taxa de transmissão em mensagens por segundo, seria necessário realizar uma coleta durante um intervalo de tempo definido.

---

# 9. Alteração da topologia

Foi realizado um experimento de alteração da topologia utilizando OSPF.

O enlace:

```text
R1 — R3
```

foi desativado durante a execução do experimento.

O comando utilizado foi:

```bash
ip link set eth2 down
```

Após a queda do enlace, foi aguardado o processo de convergência do protocolo e posteriormente verificada a rota para:

```text
192.168.50.1/32
```

Também foi realizado um novo teste de conectividade entre R1 e R5.

Arquivos relacionados:

```text
ospf_falha.txt
ospf_ping_falha.txt
```

Esse experimento permite observar como o protocolo reage a uma mudança na topologia e se uma rota alternativa pode ser utilizada.

---

# 10. Recursos computacionais

Também foi realizada uma coleta de utilização de recursos dos containers dos roteadores.

A coleta utiliza:

```bash
docker stats --no-stream
```

São observados:

* utilização de CPU;
* utilização de memória.

Arquivo:

```text
recursos.csv
```

Esses valores representam o consumo observado no momento da coleta e podem variar de uma execução para outra.

---

# 11. Gráficos

Os dados coletados são utilizados para gerar gráficos de comparação.

### Tabelas de roteamento

```text
grafico_rotas_ospf.png
grafico_rotas_rip.png
grafico_rotas_bgp.png
grafico_comparacao_rotas.png
```

Esses gráficos mostram a quantidade de entradas de roteamento observadas em cada roteador.

### Outras métricas

Quando disponíveis, os resultados também podem ser representados por gráficos de:

```text
RTT médio
perda de pacotes
utilização de CPU
utilização de memória
mensagens BGP
```

---

# 12. Interpretação dos resultados

Os resultados demonstram que os três protocolos foram capazes de fornecer conectividade entre R1 e R5 na topologia experimental.

As principais diferenças observadas foram relacionadas ao tamanho das tabelas de roteamento e aos mecanismos utilizados por cada protocolo.

O OSPF apresentou entre 16 e 17 entradas, o RIP apresentou 13 entradas em todos os roteadores e o BGP apresentou entre 9 e 10 entradas na tabela de roteamento.

Nos testes de conectividade, todos os protocolos apresentaram 0% de perda de pacotes.

Os RTTs médios observados foram próximos entre si, variando de 0,120 ms a 0,159 ms. Como o experimento foi realizado em containers no mesmo ambiente, esses valores devem ser considerados específicos do laboratório.

O experimento de alteração da topologia com OSPF permite complementar a análise com o comportamento de convergência e seleção de uma rota alternativa após a indisponibilidade de um enlace.

---

# 13. Limitações

Os resultados devem ser interpretados considerando as características do ambiente experimental.

Entre as principais limitações estão:

* execução dos roteadores em containers;
* execução dos experimentos no mesmo computador;
* pequena quantidade de roteadores;
* pequena quantidade de prefixos anunciados;
* baixa latência do ambiente virtualizado;
* coleta pontual de CPU e memória;
* quantidade limitada de pacotes ICMP;
* ausência de carga de tráfego significativa;
* métricas de mensagens de controle não coletadas continuamente.

Portanto, os resultados representam o comportamento dos protocolos **na topologia e nas condições utilizadas no laboratório**.

---

# 14. Reprodutibilidade

Os experimentos podem ser reproduzidos utilizando o script de automação localizado no diretório principal do projeto.

O protocolo utilizado é selecionado através da variável:

```bash
export PROTOCOLO=ospf
```

ou:

```bash
export PROTOCOLO=rip
```

ou:

```bash
export PROTOCOLO=bgp
```

A topologia é então criada com:

```bash
containerlab deploy -t topology.clab.yml
```

As configurações específicas de cada protocolo encontram-se em:

```text
configs/
├── ospf/
├── rip/
└── bgp/
```

Cada protocolo possui sua própria configuração de FRR para os cinco roteadores.

---

# 15. Resumo dos resultados

| Métrica                |     OSPF |      RIP |      BGP |
| ---------------------- | -------: | -------: | -------: |
| Perda de pacotes       |       0% |       0% |       0% |
| RTT médio              | 0,125 ms | 0,120 ms | 0,159 ms |
| Menor tabela observada |       16 |       13 |        9 |
| Maior tabela observada |       17 |       13 |       10 |
| R1 → R5                |       OK |       OK |       OK |

Os valores apresentados nesta tabela correspondem especificamente aos experimentos realizados nesta topologia e neste ambiente de execução.
