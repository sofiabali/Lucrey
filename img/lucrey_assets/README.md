# Assets do Lucrey (recortados para o Godot)

Todos os PNGs têm fundo transparente.

## Pastas

- `terrain/tiles/` - 26 tiles isométricos (ruas, praça, grama, ponte, praia, píeres, água).
  Todos têm o MESMO tamanho (256x200) e estão alinhados pela base, então encaixam
  direto num TileMap/TileSet sem ajuste individual.
- `terrain/tileset_atlas.png` - os mesmos tiles num atlas único (6 colunas, células 256x200).
  `terrain/tileset_atlas_index.txt` diz qual tile está em cada (coluna, linha).
- `buildings/` - 10 prédios principais (Bolsa, Corretora, Banco, Mercado, Centro de Notícias,
  Academia, Minhas Empresas, Ranking, Outras Empresas, Porto). Tamanhos originais, cada um
  recortado rente ao desenho.
- `decor/houses/` - casas e prefeitura (decoração da cidade)
- `decor/trees/` - árvores e arbustos
- `decor/cars/` - carros
- `decor/props/` - fonte, poste, banco, jardineira, cerca, veleiro, navio, pedras
- `ui/` - painéis, botões (normal e pressionado), barra do HUD, barras de progresso,
  ícones (moeda, estrela, gema, XP, sino, engrenagem, saco de dinheiro...), medalhas 1/2/3,
  avatares, toggles, barra de navegação inferior e gráfico de rosca.
- `reference/` - protótipo da interface e o mapa de exemplo, só para consulta (não usar no jogo).

## Observações

- Os recortes foram feitos automaticamente a partir das imagens; se algum contorno ficar com
  uma borda clara, dá para refinar no Godot (filtro `Nearest`/`Linear`) ou num editor de imagem.
- `hud_top_bar` e `nav_bar` são barras inteiras com os ícones já desenhados. Se quiser os
  ícones da barra inferior separados, é preciso gerar de novo (ou recortar a mão).
- Prédios, carros, árvores etc. NÃO estão normalizados: em Godot, use `Sprite2D` com
  `Offset` para apoiar a base do desenho no ponto desejado.
