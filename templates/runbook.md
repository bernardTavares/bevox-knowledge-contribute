---
title: <Verbo-substantivo>
project: <slot>
severity: p2   # p0 | p1 | p2 | p3
maintainer: <Nome>
last_tested: YYYY-MM-DD
tags: []
---

# <Verbo-substantivo>

> Runbook operacional. Quando aplicar, como executar, como verificar, como reverter.

## Quando aplicar

<!-- Sintomas, alertas, ou condições que disparam este runbook. -->

## Pre-checks

<!-- Verificações obrigatórias antes de começar. Cada uma com comando. -->

```bash
# Exemplo
systemctl status <service>
```

## Steps

<!-- Numerados, idempotentes onde possível, com comando + expected output. -->

1. ...
2. ...

## Verification

<!-- Como confirmar que o runbook resolveu o problema. Comandos + critério. -->

## Rollback

<!-- Como reverter se algo der errado. Sempre testado. -->

## Escalation

<!-- A quem escalar e quando. -->
