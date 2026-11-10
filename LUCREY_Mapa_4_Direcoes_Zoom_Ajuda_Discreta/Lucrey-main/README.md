
# Lucrey

**Jogo educativo de mercado de ações que combina matemática, estratégia e tomada de decisões.**

## Sobre o projeto

O **Lucrey** é um jogo/simulador educativo desenvolvido com o objetivo de ensinar, de forma simples e interativa, conceitos relacionados ao **mercado de ações, investimentos e matemática**.

Durante o jogo, o jogador deverá tomar decisões, acompanhar a variação dos preços e administrar seu dinheiro para alcançar seus objetivos.

O projeto também busca mostrar como a matemática pode ser utilizada em situações do dia a dia, principalmente em decisões financeiras.

---

## Objetivo

O principal objetivo do Lucrey é proporcionar uma experiência divertida de aprendizagem, na qual o jogador possa:

* Compreender o funcionamento básico do mercado de ações;
* Aprender a administrar seu dinheiro;
* Observar variações de preços;
* Utilizar conceitos matemáticos;
* Desenvolver estratégias para tomar melhores decisões;
* Aprender por meio da prática e da simulação.

---

## Como funciona?

O jogador começa com uma determinada quantia de dinheiro e deverá tomar decisões ao longo dos níveis.

As escolhas realizadas podem influenciar seus resultados financeiros, fazendo com que o jogador precise analisar as situações e escolher entre diferentes possibilidades.

O jogo será dividido em **níveis**, aumentando gradualmente a dificuldade e apresentando novos desafios.

### Níveis

* **Nível 1 — Tutorial:** introdução ao jogo e aos conceitos básicos.
* **Nível 2 — Primeiros investimentos:** primeiros contatos com compra e venda.
* **Nível 3 — Estratégia:** situações que exigem maior análise.
* **Nível 4 — Mercado:** variações e acontecimentos que afetam os preços.
* **Nível 5 — Desafios:** missões com objetivos específicos.
* **Nível 6 — Negócios:** gerenciamento e decisões financeiras.
* **Nível 7 — Desafio final:** aplicação dos conhecimentos adquiridos durante o jogo.


## 📂 Estrutura do projeto 
(por enquanto)

```text
LUCREY/
│
├── README.md
│
├── docs/
│   ├── regras-do-jogo.md
│   ├── niveis.md
│   ├── matematica.md
│   └── sistema-de-pontuacao.md
│
├── assets/
│   ├── logo.png
│   ├── telas/
│   ├── graficos/
│   └── fluxogramas/
│
├── src/
│   └── código do jogo
│
└── TODO.md
```

---

**Lucrey é um projeto em desenvolvimento e poderá receber novas funcionalidades, mecânicas e melhorias ao longo de sua criação.**


---

## Versão Cidade Viva — expansão funcional

**Abra no Godot 4:** `jogo/project.godot` (não abra a raiz do ZIP).

A versão expandida possui uma tela única que integra a cidade ilustrada em `jogo/assets/cidade_original.png` com animações procedurais (sem avatar do jogador). **Todos os preços e notícias são fictícios.**

### O que foi implementado

- 12 carros procedurais circulando automaticamente por rotas definidas, sem controle do jogador.
- 15 pedestres procedurais percorrendo calçadas e trajetos predeterminados.
- Botões de navegação e áreas clicáveis nos prédios: Bolsa, Corretora, Banco, Mercado, Praça, Notícias e Ranking.
- Corretora com seleção de ações, quantidades e compras/vendas com validação de saldo e posição.
- Carteira com quantidade, custo médio, valor de mercado, resultado e histórico de negociações.
- Cotações, gráficos de preços históricos e gráfico de evolução patrimonial.
- Eventos e notícias setoriais gerados a cada novo dia fictício.
- Seis missões verificadas automaticamente, recompensas em XP/pontos e conquistas pessoais.
- Progressão de níveis, loja de bônus fictício, tutorial inicial e controle de ambientação.
- Salvamento e recuperação JSON em `user://lucrey_save.json`; avanço do dia e negociações salvam automaticamente.

### Arquitetura

| Arquivo | Responsabilidade |
| --- | --- |
| `jogo/scenes/CenaInicial.tscn` | Cena de abertura |
| `jogo/scripts/city_game.gd` | Interface e telas funcionais |
| `jogo/scripts/city_world.gd` | Carros e pedestres automáticos |
| `jogo/scripts/price_chart.gd` | Gráficos vetoriais |
| `jogo/scripts/market.gd` | Mercado e eventos simulados |
| `jogo/scripts/game_state.gd` | Carteira, missões, XP e persistência |
| `jogo/scripts/stock.gd` | Modelo de ação e histórico |

### Controles

- **AVANÇAR DIA:** atualiza preços, notícias e patrimônio.
- **INVESTIR:** compra e venda de ativos fictícios.
- **CARTEIRA:** acompanha patrimônio e operações.
- **COTAÇÕES:** consulta preços e acessa gráficos por empresa.
- **MISSÕES / CONQUISTAS:** acompanha metas e recompensas.
- **LOJA:** troca pontos por um bônus fictício de saldo.
- **AJUSTES:** salva/carrega partida, liga/desliga a ambientação e reinicia.
- **MAPA:** fecha os painéis e retorna à cidade.

### Limitações e próximos passos

- A arte original é uma **imagem única**, com veículos e painéis estáticos já desenhados. A animação foi implementada em **camadas sobrepostas**, sem redesenhar ou apagar a arte do autor. A separação dos elementos do fundo em sprites e a remoção dos carros estáticos permitiriam um acabamento superior.
- Os veículos e pedestres são formas vetoriais pequenas e animadas, não sprites ilustrados do mesmo estilo da imagem. São uma primeira implementação jogável.
- Rotas são fixas, sem semáforos, colisões entre carros ou navegação dinâmica; isso pode ser acrescentado posteriormente.
- O ranking é pessoal/local, **não** inventa adversários e não tem servidor multiplayer.
- O salvamento usa o armazenamento local da Godot. Não há conta nem sincronização na nuvem.
- O código foi revisado estaticamente neste ambiente, mas o executável da Godot **não estava instalado para teste de execução**. Ao abrir o projeto na engine, use o painel de erros do editor para validar importação e compatibilidade.
