class_name ContentData
extends RefCounted

static func glossary() -> Array[Dictionary]:
	return [
		{
			"term": "Línea de scrimmage",
			"def": "Línea imaginaria donde comienza cada jugada. Las formaciones se colocan respecto a ella."
		},
		{
			"term": "Oportunidad (down)",
			"def": "Cada intento de avance. Tienes 4 oportunidades para ganar al menos 10 yardas (1ª y 10)."
		},
		{
			"term": "1ª y 10 / 1ª y Gol",
			"def": "Primera oportunidad con 10 yardas por avanzar. Si estás dentro de las últimas 10 yardas rivales, se llama 1ª y Gol."
		},
		{
			"term": "Touchdown",
			"def": "Anotar al llegar a la zona de anotación rival. Vale 6 puntos y permite intentar punto extra o conversión de 2."
		},
		{
			"term": "Gol de campo",
			"def": "Patada a través de los postes. Vale 3 puntos. Distancia = posición del balón + 17 yardas."
		},
		{
			"term": "Punto extra / Conversión",
			"def": "Tras un touchdown: patada de 37 yardas (1 punto) o avance desde la yarda 2 (2 puntos)."
		},
		{
			"term": "Safety",
			"def": "La defensa captura al atacante dentro de su propia zona de anotación. Vale 2 puntos e intercambio de balón."
		},
		{
			"term": "Despeje (punt)",
			"def": "Entregar el balón lo más lejos posible cuando se acaban las oportunidades. Garantiza al menos 25 yardas de patada."
		},
		{
			"term": "Intercepción / Balón suelto",
			"def": "La defensa recupera el balón. Los roles de ataque y defensa se intercambian."
		},
		{
			"term": "Sack / Captura",
			"def": "La defensa derriba al pasador detrás de la línea. Pierdes yardas según la diferencia de dados."
		},
		{
			"term": "Tiempo fuera",
			"def": "Alarga el cuarto una jugada y permite cambiar la alineación. 2 por equipo por mitad; no consecutivos del mismo equipo."
		},
		{
			"term": "Castigo",
			"def": "Tras una jugada puedes forzar un dado al rival. Si saca 6, se anula el resultado y se aplican 5/10/15 yardas en ciclo."
		},
	]


static func rules_sections() -> Array[Dictionary]:
	return [
		{
			"title": "Objetivo",
			"body": "Dos equipos se enfrentan en 4 cuartos. Gana quien tenga más puntos al terminar todas las jugadas del partido."
		},
		{
			"title": "Marcador",
			"body": "Touchdown 6 · Gol de campo 3 · Punto extra 1 · Conversión 2 · Safety 2."
		},
		{
			"title": "Flujo de una jugada",
			"body": "1) Ambos colocan formaciones en secreto.\n2) Se revelan.\n3) El ataque elige pase, carrera, despeje o gol de campo (según contexto).\n4) Se lanzan dados por zonas.\n5) Se aplican yardas, turnovers o anotaciones."
		},
		{
			"title": "Ataque por pase",
			"body": "Requiere al menos 1 receptor.\n• Tiro de línea (OL vs DL) → Tabla B: contención, presión, sack o fumble.\n• Si el pase sigue: tiro de secundaria (receptores vs esquineros) → completo, incompleto, intercepción o TD.\n• Si es completo: tiro profundo (1 dado vs profundos). Si gana el ataque se suman las 3 diferencias para yardas; si gana la defensa, solo las 2 primeras. Las yardas por punto salen de la Tabla C."
		},
		{
			"title": "Ataque por carrera",
			"body": "Requiere 1 corredor.\n• Tiro de línea: aplica sack/fumble (Tabla B) y ganar/perder yardas.\n• Si el ataque gana la línea: tiro de apoyadores (1 dado vs LBs).\n• Si vuelve a ganar: tiro de retaguardia (1 dado vs retaguardia). Extra de +3 yardas por punto en el tercer tiro si gana el ataque."
		},
		{
			"title": "Despeje",
			"body": "Patada mínima 25 yd. Tiro de línea (protección vs presión) y tiro de cobertura. Puede haber touchback (rival en yarda 20) o TD de regreso."
		},
		{
			"title": "Gol de campo",
			"body": "Distancia = posición + 17. Cada lado lanza 2 dados. Longitud = 42 + (diff × 2). Si alcanza la distancia: 3 puntos y rival en yarda 20. Si falla: rival comienza 7 yardas adelante."
		},
		{
			"title": "Formaciones",
			"body": "7 fichas por equipo.\nOfensiva: pasador obligatorio (1), corredor 0–1, línea y receptores 0–N.\nDefensa: línea, apoyadores, retaguardia, esquineros I/D, profundos I/D. Sin fichas en una zona = 0 dados en esa zona."
		},
		{
			"title": "Duración",
			"body": "Al inicio eliges Corto (10), Mediano (15) o Largo (20) jugadas por cuarto. El 3er cuarto arranca con ataque del que defendió al inicio, en su yarda 20."
		},
	]
