# Data

Implementações dos protocolos de repositório declarados em `Domain/`.

Vazio até a **fase 4** do plano em `docs/ARQUITETURA.md`. Quando chegar lá:

```
Data/
├── InMemory/    dados de exemplo — o que hoje vive dentro dos modelos
└── Remote/      cliente da API
```

A regra que sustenta a camada: `Features/` depende do **protocolo** em
`Domain/`, nunca de uma implementação daqui. É isso que permite trocar dados
falsos por API sem tocar em View nenhuma.
