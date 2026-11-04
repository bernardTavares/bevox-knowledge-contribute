---
project: <slot>
owner: <Nome>
last_updated: YYYY-MM-DD
type: leading   # leading | lagging | operational | quality
tags: []
---

# <Nome da métrica>

## Definição

<!-- O que esta métrica mede em 1-2 linhas. -->

## Cálculo

<!-- Fórmula. Pseudocódigo ou SQL é melhor que prosa. -->

```
<formula ou query>
```

## Fonte de dados

<!-- Tabelas / serviços / dashboards que produzem os números. -->

## Threshold

<!-- Valores esperados. Verde / amarelo / vermelho. -->

| Faixa | Valor | Ação |
|---|---|---|
| Verde | ... | ... |
| Amarelo | ... | ... |
| Vermelho | ... | ... |

## Alerting

<!-- Onde dispara alerta, pra quem, com que latência. -->

## Histórico

<!-- Snapshots periódicos. Apenas se relevante manter no doc. -->
