# Tactic Board Football

Juego de mesa de football americano convertido a Godot 4.7 (MVP web).

## Cómo jugar (local)

1. Abre el proyecto con Godot 4.7+.
2. Ejecuta la escena principal (`scenes/ui/main_menu.tscn`).
3. Elige equipo fake, duración y empieza vs CPU.

## Export web (Netlify)

1. En Godot: **Project → Export → Web**.
2. Exporta a una carpeta `build/web` (incluye `index.html`, `.wasm`, `.pck`).
3. En Netlify, publica esa carpeta.
4. Cabeceras recomendadas (archivo `build/web/_headers` o config Netlify):

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

Godot Web necesita esas cabeceras para `SharedArrayBuffer` en builds con hilos. Si exportas **sin threads**, puede funcionar sin ellas.

## Créditos

Application created by [quezadasergio](https://github.com/quezadasergio)
