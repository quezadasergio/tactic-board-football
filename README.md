# Tactic Board Football

Juego de mesa de football americano en Godot 4.7 (MVP web, 1 jugador vs CPU).

## Proyecto Godot

El juego está en la carpeta [`tactic-board-football/`](tactic-board-football/).

## Export a Netlify

Netlify publica la carpeta `public/` (build web ya generado).

1. Abre el subproyecto en Godot 4.7.
2. **Project → Export → Web** hacia `tactic-board-football/export/web/`.
3. Copia el build a `public/`:

```bash
rsync -a --exclude='*.import' tactic-board-football/export/web/ public/
```

4. Commit + push a `main`.

## Créditos

Application created by [quezadasergio](https://github.com/quezadasergio)
