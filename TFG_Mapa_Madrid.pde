
import processing.data.*;
import processing.serial.*;
import java.util.*;

// =====================================================
// 1. DATOS GEOGRAFICOS
// =====================================================

JSONObject madrid;

float minLon = Float.MAX_VALUE;
float maxLon = -Float.MAX_VALUE;
float minLat = Float.MAX_VALUE;
float maxLat = -Float.MAX_VALUE;


// =====================================================
// 2. CONFIGURACION DEL MAPA
// =====================================================

float mapaX;
float mapaY;
float mapaAncho;
float mapaAlto;


// =====================================================
// 3. SELECCION DE ZONAS
// =====================================================

// Navegacion de las nueve zonas mediante teclado.

int zonaColumna = 1;
int zonaFila = 1;

color colorSeleccion = color(45, 180, 255);


// =====================================================
// 4. COMUNICACION CON ARDUINO
// =====================================================

Serial puertoArduino;

int botonAireAnterior = 0;
int botonVerdeAnterior = 0;
int botonTraficoAnterior = 0;
int resetAnterior = 0;

int valorPotenciometro = 0;
int valorPotenciometroAnterior = 0;

boolean potenciometroInicializado = false;


// =====================================================
// 5. INDICADORES AMBIENTALES
// =====================================================

// -1 = Vista general
//  0 = Calidad del aire
//  1 = Zonas verdes
//  2 = Trafico urbano

int indicadorSeleccionado = -1;

boolean modoSimulacion = false;


// Valores provisionales para las nueve zonas.
// Orden: fila por fila, de izquierda a derecha.
// No representan mediciones reales.

float[] aireInicial = {
  43, 46, 48,
  45, 51, 55,
  53, 57, 60
};

float[] verdeInicial = {
  35, 39, 44,
  42, 48, 52,
  46, 50, 55
};

float[] traficoInicial = {
  65, 60, 57,
  63, 55, 50,
  58, 52, 47
};


// Valores actuales.

float[] valoresAire = new float[9];
float[] valoresVerdes = new float[9];
float[] valoresTrafico = new float[9];

// Valor combinado de sostenibilidad.

float[] valoresZonas = new float[9];


// =====================================================
// 6. PARTICULAS AMBIENTALES
// =====================================================

// Cantidad de particulas por zona.

final int NUM_PUNTOS_PRINCIPALES = 180;
final int NUM_PUNTOS_TRANSICION = 550;

ArrayList<Particula> puntosPrincipales =
  new ArrayList<Particula>();

ArrayList<Particula> puntosTransicion =
  new ArrayList<Particula>();


// =====================================================
// 7. PALETA DE COLORES
// =====================================================

color fondo = color(5, 9, 20);
color superficie = color(12, 27, 49);
color borde = color(45, 155, 225);

color colorPuntos = color(65, 105, 145, 105);
color colorPuntosGuia = color(150, 185, 215, 115);

// Colores ambientales.

color nivelMuyBien = color(55, 190, 110);
color nivelBien = color(160, 195, 75);
color nivelRegular = color(230, 175, 55);
color nivelMal = color(235, 105, 55);
color nivelMuyMal = color(220, 55, 65);


// =====================================================
// 8. CONFIGURACION DE LA CUADRICULA
// =====================================================

float separacionPuntos = 60;
float tamanoPuntos = 4;

float separacionGuia = 6;
float tamanoPuntosGuia = 1.2;


// =====================================================
// 9. INICIALIZACION
// =====================================================

void setup() {

  fullScreen(P2D);
  smooth(8);

  float proporcionMapa = 780.0 / 625.0;

  mapaAncho = min(
    width * 0.56,
    height * 0.72 * proporcionMapa
  );

  mapaAlto = mapaAncho / proporcionMapa;

  mapaX = (width - mapaAncho) / 2;
  mapaY = (height - mapaAlto) / 2 + 35;

  // Cargar GeoJSON.

  madrid = loadJSONObject("madrid.geojson");

  if (madrid == null) {

    println("ERROR: No se encuentra madrid.geojson");
    exit();
    return;
  }

  calcularLimites();

  // Inicializar datos.

  reiniciarDatos();

  // Generar particulas.

  generarParticulas();

  // Conectar Arduino.

  try {

    puertoArduino = new Serial(this, "COM11", 9600);

    puertoArduino.clear();
    puertoArduino.bufferUntil('\n');

    println("Arduino conectado en COM11");

  } catch (Exception e) {

    println("No se ha podido conectar con Arduino.");
    println("Comprueba COM11 y cierra el Monitor Serie.");

  }

  println("Mapa de Madrid cargado correctamente");
  println("Resolucion: " + width + " x " + height);
}


// =====================================================
// 10. DIBUJO PRINCIPAL
// =====================================================

void draw() {

  background(fondo);

  dibujarCuadricula();

  dibujarRelieve();

  dibujarSilueta(
    0, 0,
    superficie,
    true,
    1
  );

  dibujarSilueta(
    0, 0,
    borde,
    false,
    2
  );

  dibujarParticulas();

  dibujarZonaSeleccionada();

  dibujarPaneles();

  dibujarCabecera();
}


// =====================================================
// 11. CUADRICULA DE PUNTOS
// =====================================================

void dibujarCuadricula() {

  noStroke();

  fill(colorPuntosGuia);

  for (
    float x = 20;
    x < width;
    x += separacionPuntos
  ) {

    for (
      float y = 20;
      y < height;
      y += separacionPuntos
    ) {

      for (
        float distancia = separacionGuia;
        distancia < separacionPuntos;
        distancia += separacionGuia
      ) {

        ellipse(
          x + distancia,
          y,
          tamanoPuntosGuia,
          tamanoPuntosGuia
        );
      }

      for (
        float distancia = separacionGuia;
        distancia < separacionPuntos;
        distancia += separacionGuia
      ) {

        ellipse(
          x,
          y + distancia,
          tamanoPuntosGuia,
          tamanoPuntosGuia
        );
      }
    }
  }

  fill(colorPuntos);

  for (
    float x = 20;
    x < width;
    x += separacionPuntos
  ) {

    for (
      float y = 20;
      y < height;
      y += separacionPuntos
    ) {

      ellipse(
        x,
        y,
        tamanoPuntos,
        tamanoPuntos
      );
    }
  }
}


// =====================================================
// 12. CABECERA CENTRAL
// =====================================================

void dibujarCabecera() {

  float anchoCabecera = 440;
  float altoCabecera = 105;

  float x = (width - anchoCabecera) / 2;
  float y = 22;

  fill(8, 16, 31);
  stroke(38, 65, 95);
  strokeWeight(1);

  rect(
    x, y,
    anchoCabecera, altoCabecera,
    6
  );

  fill(235, 242, 252);
  textSize(38);
  textAlign(CENTER, CENTER);

  text(
    "MADRID",
    width / 2,
    y + 38
  );

  fill(100, 165, 215);
  textSize(15);

  text(
    "URBAN ENVIRONMENTAL MONITORING",
    width / 2,
    y + 76
  );

  textAlign(LEFT, BASELINE);
}


// =====================================================
// 13. DISTRIBUCION DE LOS PANELES
// =====================================================

void dibujarPaneles() {

  float anchoPanel = min(320, width * 0.24);

  float altoSuperior = 210;
  float altoInferior = 220;

  dibujarPanelBase(
    25, 25,
    anchoPanel, altoSuperior,
    "FUNCIONALIDADES"
  );

  dibujarFuncionalidades(45, 100);


  dibujarPanelBase(
    width - anchoPanel - 25,
    25,
    anchoPanel,
    altoSuperior,
    "INDICADOR"
  );

  dibujarIndicador(
    width - anchoPanel - 5,
    100
  );


  dibujarPanelBase(
    25,
    height - altoInferior - 25,
    anchoPanel,
    altoInferior,
    "CONTROLES"
  );

  dibujarControles(
    45,
    height - altoInferior + 55
  );


  dibujarPanelBase(
    width - anchoPanel - 25,
    height - altoInferior - 25,
    anchoPanel,
    altoInferior,
    "LEYENDA"
  );

  dibujarLeyenda(
    width - anchoPanel + 5,
    height - altoInferior + 55
  );
}


// =====================================================
// 14. ESTRUCTURA VISUAL DE LOS PANELES
// =====================================================

void dibujarPanelBase(
  float x,
  float y,
  float ancho,
  float alto,
  String titulo
) {

  fill(8, 16, 31);

  stroke(38, 65, 95);
  strokeWeight(1);

  rect(
    x, y,
    ancho, alto,
    5
  );

  stroke(38, 65, 95, 180);

  line(
    x + 15,
    y + 52,
    x + ancho - 15,
    y + 52
  );

  fill(145, 185, 220);
  textSize(17);
  textAlign(LEFT, BASELINE);

  text(
    titulo,
    x + 18,
    y + 34
  );
}


// =====================================================
// 15. PANEL DE FUNCIONALIDADES
// =====================================================

void dibujarFuncionalidades(float x, float y) {

  textSize(15);

  fill(220, 230, 245);
  text("01", x, y);

  fill(190, 210, 230);
  text("Calidad del aire", x + 35, y);

  fill(220, 230, 245);
  text("02", x, y + 42);

  fill(190, 210, 230);
  text("Zonas verdes", x + 35, y + 42);

  fill(220, 230, 245);
  text("03", x, y + 84);

  fill(190, 210, 230);
  text("Trafico urbano", x + 35, y + 84);
}


// =====================================================
// 16. PANEL DEL INDICADOR
// =====================================================

void dibujarIndicador(float x, float y) {

  String nombreIndicador;

  if (indicadorSeleccionado == 0) {
    nombreIndicador = "CALIDAD DEL AIRE";
  } else if (indicadorSeleccionado == 1) {
    nombreIndicador = "ZONAS VERDES";
  } else if (indicadorSeleccionado == 2) {
    nombreIndicador = "TRAFICO URBANO";
  } else {
    nombreIndicador = "VISTA GENERAL";
  }

  float valorGlobal = obtenerMediaGlobal();
  float valorLocal = obtenerValorLocal();

  fill(125, 165, 205);
  textSize(14);
  text(nombreIndicador, x, y);

  fill(220, 230, 245);
  textSize(15);
  text("Valor global:", x, y + 34);

  fill(100, 190, 230);
  textSize(22);
  text(nf(valorGlobal, 0, 1) + " %", x + 145, y + 36);

  fill(220, 230, 245);
  textSize(14);
  text("Zona seleccionada:", x, y + 69);

  fill(100, 190, 230);
  text(
    "Zona " + (zonaFila * 3 + zonaColumna + 1),
    x + 145,
    y + 69
  );

  fill(220, 230, 245);
  text("Valor local:", x, y + 98);

  fill(100, 190, 230);
  text(nf(valorLocal, 0, 1) + " %", x + 145, y + 98);

  if (modoSimulacion) {

    fill(235, 175, 65);
    text("MODO SIMULACION", x, y + 130);

  } else {

    fill(80, 205, 150);
    text("DATOS REALES", x, y + 130);

  }
}


// =====================================================
// 17. PANEL DE CONTROLES
// =====================================================

void dibujarControles(float x, float y) {

  textSize(14);
  fill(190, 210, 230);

  text("Flechas: mover por el mapa", x, y);
  text("Botones: cambiar indicador", x, y + 30);
  text("Repetir boton: vista general", x, y + 60);
  text("Potenciometro: modificar valor", x, y + 90);

  fill(100, 190, 230);
  text("RESET: restaurar datos", x, y + 120);
}


// =====================================================
// 18. PANEL DE LEYENDA AMBIENTAL
// =====================================================

void dibujarLeyenda(float x, float y) {

  textSize(14);

  dibujarNivel(x, y, nivelMuyBien, "Muy bien");
  dibujarNivel(x, y + 32, nivelBien, "Bien");
  dibujarNivel(x, y + 64, nivelRegular, "Ni bien ni mal");
  dibujarNivel(x, y + 96, nivelMal, "Mal");
  dibujarNivel(x, y + 128, nivelMuyMal, "Muy mal");
}


// =====================================================
// 19. DIBUJAR CADA NIVEL DE LA LEYENDA
// =====================================================

void dibujarNivel(
  float x,
  float y,
  color colorNivel,
  String descripcion
) {

  noStroke();
  fill(colorNivel);

  rect(
    x,
    y - 11,
    15,
    15,
    3
  );

  fill(190, 210, 230);

  text(
    descripcion,
    x + 27,
    y + 2
  );
}


// =====================================================
// 20. CALCULAR LIMITES GEOGRAFICOS
// =====================================================

void calcularLimites() {

  JSONArray features =
    madrid.getJSONArray("features");

  for (
    int f = 0;
    f < features.size();
    f++
  ) {

    JSONObject geometria = features
      .getJSONObject(f)
      .getJSONObject("geometry");

    String tipo =
      geometria.getString("type");

    JSONArray coordenadas =
      geometria.getJSONArray("coordinates");

    if (tipo.equals("MultiPolygon")) {

      for (
        int p = 0;
        p < coordenadas.size();
        p++
      ) {

        procesarAnillo(
          coordenadas.getJSONArray(p)
          .getJSONArray(0)
        );
      }

    } else if (tipo.equals("Polygon")) {

      procesarAnillo(
        coordenadas.getJSONArray(0)
      );
    }
  }
}


// =====================================================
// 21. PROCESAR COORDENADAS
// =====================================================

void procesarAnillo(JSONArray anillo) {

  for (
    int i = 0;
    i < anillo.size();
    i++
  ) {

    JSONArray punto =
      anillo.getJSONArray(i);

    float lon = punto.getFloat(0);
    float lat = punto.getFloat(1);

    minLon = min(minLon, lon);
    maxLon = max(maxLon, lon);

    minLat = min(minLat, lat);
    maxLat = max(maxLat, lat);
  }
}


// =====================================================
// 22. RELIEVE Y PROFUNDIDAD
// =====================================================

void dibujarRelieve() {

  for (
    int i = 12;
    i >= 1;
    i--
  ) {

    dibujarSilueta(
      i * 1.2,
      i * 1.5,
      color(0, 0, 0, 12),
      false,
      0.5
    );
  }
}


// =====================================================
// 23. DIBUJAR SILUETA MUNICIPAL
// =====================================================

void dibujarSilueta(
  float desplazamientoX,
  float desplazamientoY,
  color colorMapa,
  boolean rellenar,
  float grosor
) {

  JSONArray features =
    madrid.getJSONArray("features");

  if (rellenar) {
    fill(colorMapa);
  } else {
    noFill();
  }

  stroke(colorMapa);
  strokeWeight(grosor);

  for (
    int f = 0;
    f < features.size();
    f++
  ) {

    JSONObject geometria = features
      .getJSONObject(f)
      .getJSONObject("geometry");

    String tipo =
      geometria.getString("type");

    JSONArray coordenadas =
      geometria.getJSONArray("coordinates");

    if (tipo.equals("MultiPolygon")) {

      for (
        int p = 0;
        p < coordenadas.size();
        p++
      ) {

        dibujarAnillo(
          coordenadas.getJSONArray(p)
          .getJSONArray(0),
          desplazamientoX,
          desplazamientoY
        );
      }

    } else if (tipo.equals("Polygon")) {

      dibujarAnillo(
        coordenadas.getJSONArray(0),
        desplazamientoX,
        desplazamientoY
      );
    }
  }
}


// =====================================================
// 24. DIBUJAR ANILLO GEOGRAFICO
// =====================================================

void dibujarAnillo(
  JSONArray anillo,
  float desplazamientoX,
  float desplazamientoY
) {

  beginShape();

  for (
    int i = 0;
    i < anillo.size();
    i++
  ) {

    JSONArray punto =
      anillo.getJSONArray(i);

    float x = map(
      punto.getFloat(0),
      minLon,
      maxLon,
      mapaX,
      mapaX + mapaAncho
    );

    float y = map(
      punto.getFloat(1),
      maxLat,
      minLat,
      mapaY,
      mapaY + mapaAlto
    );

    vertex(
      x + desplazamientoX,
      y + desplazamientoY
    );
  }

  endShape(CLOSE);
}


// =====================================================
// 25. DIBUJAR ZONA SELECCIONADA
// =====================================================

void dibujarZonaSeleccionada() {

  float anchoZona = mapaAncho / 3.0;
  float altoZona = mapaAlto / 3.0;

  float x = mapaX + zonaColumna * anchoZona;
  float y = mapaY + zonaFila * altoZona;

  float oscilacion =
    (sin(frameCount * 0.1) + 1) / 2;

  int alphaBorde =
    (int) map(oscilacion, 0, 1, 100, 255);

  noStroke();
  fill(45, 180, 255, 25);
  rect(x, y, anchoZona, altoZona);

  stroke(45, 180, 255, alphaBorde);
  strokeWeight(5);
  noFill();
  rect(x, y, anchoZona, altoZona);

  stroke(100, 210, 255, alphaBorde);
  strokeWeight(1.5);
  rect(x, y, anchoZona, altoZona);
}


// =====================================================
// 26. CONTROL DE SELECCION CON TECLADO
// =====================================================

void keyPressed() {

  if (key == '1') {
    seleccionarIndicador(0);
  }

  if (key == '2') {
    seleccionarIndicador(1);
  }

  if (key == '3') {
    seleccionarIndicador(2);
  }

  if (key == '0') {
    indicadorSeleccionado = -1;
  }

  if (key == 'r' || key == 'R') {
    reiniciarDatos();
  }

  if (keyCode == LEFT) {
    zonaColumna--;
  }

  if (keyCode == RIGHT) {
    zonaColumna++;
  }

  if (keyCode == UP) {
    zonaFila--;
  }

  if (keyCode == DOWN) {
    zonaFila++;
  }

  zonaColumna = constrain(zonaColumna, 0, 2);
  zonaFila = constrain(zonaFila, 0, 2);
}


// =====================================================
// 27. CLASE PARTICULA
// =====================================================

class Particula {

  float x;
  float y;
  float tamano;

  float valor;
  float desviacion;

  float fase;
  float velocidad;
  float intensidad;

  color tono;

  boolean principal;
  boolean parpadea;

  int zona;


  Particula(
    float px,
    float py,
    float pvalor,
    boolean esPrincipal,
    int zonaAsignada
  ) {

    x = px;
    y = py;

    valor = pvalor;
    principal = esPrincipal;
    zona = zonaAsignada;

    desviacion = pvalor - valoresZonas[zona];

    fase = random(TWO_PI);
    velocidad = random(0.015, 0.035);
    intensidad = random(0.65, 1.0);

    // 35% parpadean y 65% permanecen estables.

    parpadea = random(1) < 0.35;

    if (principal) {
      tamano = 3.2;
    } else {
      tamano = random(1.0, 2.0);
    }

    tono = colorPorValor(valor);
  }


  void dibujar() {

    float valorActual = valorBaseParaZona(zona);

    valorActual = constrain(
      valorActual + desviacion,
      0,
      100
    );

    tono = colorPorValor(valorActual);

    float brillo;

    if (parpadea) {

      brillo = map(
        sin(frameCount * velocidad + fase),
        -1,
        1,
        0.45,
        1.0
      );

    } else {

      brillo = 0.82;
    }

    brillo *= intensidad;

    float transparencia = map(
      brillo,
      0,
      1,
      95,
      255
    );

    noStroke();

    if (principal) {

      // Halo exterior.

      fill(
        red(tono),
        green(tono),
        blue(tono),
        transparencia * 0.12
      );

      ellipse(
        x, y,
        tamano * 5,
        tamano * 5
      );

      // Halo interior.

      fill(
        red(tono),
        green(tono),
        blue(tono),
        transparencia * 0.35
      );

      ellipse(
        x, y,
        tamano * 2.5,
        tamano * 2.5
      );

      // Punto principal.

      fill(
        red(tono),
        green(tono),
        blue(tono),
        transparencia
      );

      ellipse(
        x, y,
        tamano,
        tamano
      );

    } else {

      // Punto secundario.

      fill(
        red(tono),
        green(tono),
        blue(tono),
        transparencia * 0.55
      );

      ellipse(
        x, y,
        tamano,
        tamano
      );
    }
  }
}


// =====================================================
// 28. GENERAR PARTICULAS DE LAS NUEVE ZONAS
// =====================================================

void generarParticulas() {

  puntosPrincipales.clear();
  puntosTransicion.clear();

  float anchoZona = mapaAncho / 3.0;
  float altoZona = mapaAlto / 3.0;

  for (int fila = 0; fila < 3; fila++) {

    for (int columna = 0; columna < 3; columna++) {

      int indice = fila * 3 + columna;

      float mediaZona = valoresZonas[indice];

      float xZona = mapaX + columna * anchoZona;
      float yZona = mapaY + fila * altoZona;

      ArrayList<Particula> puntosZona =
        new ArrayList<Particula>();

      // -------------------------------------------
      // PARTICULAS PRINCIPALES
      // -------------------------------------------

      int creados = 0;
      int intentos = 0;

      while (
        creados < NUM_PUNTOS_PRINCIPALES &&
        intentos < NUM_PUNTOS_PRINCIPALES * 30
      ) {

        intentos++;

        PVector posicion = crearPosicionEnZona(
          xZona, yZona,
          anchoZona, altoZona
        );

        if (posicion == null) {
          continue;
        }

        float variacion = random(
          -8,
          8
        );

        float valor = constrain(
          mediaZona + variacion,
          0,
          100
        );

        Particula p = new Particula(
          posicion.x,
          posicion.y,
          valor,
          true,
          indice
        );

        puntosPrincipales.add(p);
        puntosZona.add(p);

        creados++;
      }

      // -------------------------------------------
      // PARTICULAS SECUNDARIAS
      // -------------------------------------------

      creados = 0;
      intentos = 0;

      while (
        creados < NUM_PUNTOS_TRANSICION &&
        intentos < NUM_PUNTOS_TRANSICION * 30
      ) {

        intentos++;

        PVector posicion = crearPosicionEnZona(
          xZona, yZona,
          anchoZona, altoZona
        );

        if (posicion == null) {
          continue;
        }

        float valor = mediaZona + random(-5, 5);

        Particula secundaria = new Particula(
          posicion.x,
          posicion.y,
          valor,
          false,
          indice
        );

        puntosTransicion.add(secundaria);

        creados++;
      }

      println(
        "Zona " + (indice + 1) +
        ": " + puntosZona.size() +
        " puntos principales"
      );
    }
  }

  println("Total puntos principales: " +
    puntosPrincipales.size());

  println("Total puntos de transicion: " +
    puntosTransicion.size());
}


// =====================================================
// 29. GENERAR POSICION DENTRO DE UNA ZONA
// =====================================================

PVector crearPosicionEnZona(
  float xZona,
  float yZona,
  float anchoZona,
  float altoZona
) {

  for (int intento = 0; intento < 500; intento++) {

    float px = random(xZona, xZona + anchoZona);
    float py = random(yZona, yZona + altoZona);

    if (puntoDentroMadrid(px, py)) {

      return new PVector(px, py);
    }
  }

  return null;
}


// =====================================================
// 30. ASIGNAR COLOR SEGUN VALOR AMBIENTAL
// =====================================================

color colorPorValor(float valor) {

  valor = constrain(valor, 0, 100);

  if (valor < 20) {

    return lerpColor(
      nivelMuyMal,
      nivelMal,
      valor / 20.0
    );
  }

  if (valor < 40) {

    return lerpColor(
      nivelMal,
      nivelRegular,
      (valor - 20) / 20.0
    );
  }

  if (valor < 60) {

    return lerpColor(
      nivelRegular,
      nivelBien,
      (valor - 40) / 20.0
    );
  }

  if (valor < 80) {

    return lerpColor(
      nivelBien,
      nivelMuyBien,
      (valor - 60) / 20.0
    );
  }

  return nivelMuyBien;
}


// =====================================================
// 31. COMPROBAR SI UN PUNTO ESTA DENTRO DE MADRID
// =====================================================

boolean puntoDentroMadrid(float px, float py) {

  JSONArray features =
    madrid.getJSONArray("features");

  for (int f = 0; f < features.size(); f++) {

    JSONObject geometria = features
      .getJSONObject(f)
      .getJSONObject("geometry");

    String tipo = geometria.getString("type");

    JSONArray coordenadas =
      geometria.getJSONArray("coordinates");

    if (tipo.equals("MultiPolygon")) {

      for (int p = 0; p < coordenadas.size(); p++) {

        JSONArray anillo = coordenadas
          .getJSONArray(p)
          .getJSONArray(0);

        if (puntoDentroAnillo(px, py, anillo)) {
          return true;
        }
      }

    } else if (tipo.equals("Polygon")) {

      JSONArray anillo = coordenadas.getJSONArray(0);

      if (puntoDentroAnillo(px, py, anillo)) {
        return true;
      }
    }
  }

  return false;
}


// =====================================================
// 32. COMPROBAR SI UN PUNTO ESTA DENTRO DE UN ANILLO
// =====================================================

boolean puntoDentroAnillo(
  float px,
  float py,
  JSONArray anillo
) {

  boolean dentro = false;

  int j = anillo.size() - 1;

  for (int i = 0; i < anillo.size(); i++) {

    JSONArray punto1 = anillo.getJSONArray(i);
    JSONArray punto2 = anillo.getJSONArray(j);

    float x1 = map(
      punto1.getFloat(0),
      minLon,
      maxLon,
      mapaX,
      mapaX + mapaAncho
    );

    float y1 = map(
      punto1.getFloat(1),
      maxLat,
      minLat,
      mapaY,
      mapaY + mapaAlto
    );

    float x2 = map(
      punto2.getFloat(0),
      minLon,
      maxLon,
      mapaX,
      mapaX + mapaAncho
    );

    float y2 = map(
      punto2.getFloat(1),
      maxLat,
      minLat,
      mapaY,
      mapaY + mapaAlto
    );

    boolean interseccion =
      ((y1 > py) != (y2 > py)) &&
      (px < (x2 - x1) * (py - y1) /
      (y2 - y1) + x1);

    if (interseccion) {
      dentro = !dentro;
    }

    j = i;
  }

  return dentro;
}


// =====================================================
// 33. DIBUJAR TODAS LAS PARTICULAS
// =====================================================

void dibujarParticulas() {

  for (Particula p : puntosTransicion) {
    p.dibujar();
  }

  for (Particula p : puntosPrincipales) {
    p.dibujar();
  }
}


// =====================================================
// 34. ACTUALIZAR VALOR COMBINADO
// =====================================================

void actualizarCombinados() {

  for (int i = 0; i < 9; i++) {

    valoresZonas[i] = (
      valoresAire[i] +
      valoresVerdes[i] +
      (100 - valoresTrafico[i])
    ) / 3.0;
  }
}


// =====================================================
// 35. REINICIAR DATOS
// =====================================================

void reiniciarDatos() {

  arrayCopy(aireInicial, valoresAire);
  arrayCopy(verdeInicial, valoresVerdes);
  arrayCopy(traficoInicial, valoresTrafico);

  actualizarCombinados();

  indicadorSeleccionado = -1;
  modoSimulacion = false;

  println("Datos originales restaurados");
}


// =====================================================
// 36. OBTENER VALOR PARA COLOREAR LAS PARTICULAS
// =====================================================

float valorBaseParaZona(int zona) {

  if (indicadorSeleccionado == 0) {
    return valoresAire[zona];
  }

  if (indicadorSeleccionado == 1) {
    return valoresVerdes[zona];
  }

  if (indicadorSeleccionado == 2) {

    // Mas trafico = peor resultado.

    return 100 - valoresTrafico[zona];
  }

  return valoresZonas[zona];
}


// =====================================================
// 37. OBTENER MEDIA GLOBAL
// =====================================================

float obtenerMediaGlobal() {

  float suma = 0;

  for (int i = 0; i < 9; i++) {

    if (indicadorSeleccionado == 0) {
      suma += valoresAire[i];
    }

    else if (indicadorSeleccionado == 1) {
      suma += valoresVerdes[i];
    }

    else if (indicadorSeleccionado == 2) {
      suma += valoresTrafico[i];
    }

    else {
      suma += valoresZonas[i];
    }
  }

  return suma / 9.0;
}


// =====================================================
// 38. OBTENER VALOR LOCAL
// =====================================================

float obtenerValorLocal() {

  int indice = zonaFila * 3 + zonaColumna;

  if (indicadorSeleccionado == 0) {
    return valoresAire[indice];
  }

  if (indicadorSeleccionado == 1) {
    return valoresVerdes[indice];
  }

  if (indicadorSeleccionado == 2) {
    return valoresTrafico[indice];
  }

  return valoresZonas[indice];
}


// =====================================================
// 39. SELECCIONAR INDICADOR
// =====================================================

void seleccionarIndicador(int nuevoIndicador) {

  if (indicadorSeleccionado == nuevoIndicador) {

    // El mismo boton devuelve a la vista general.

    indicadorSeleccionado = -1;

  } else {

    indicadorSeleccionado = nuevoIndicador;
  }

  // Evitar un cambio inmediato al seleccionar.

  valorPotenciometroAnterior = valorPotenciometro;

  println("Indicador seleccionado: " +
    indicadorSeleccionado);
}


// =====================================================
// 40. RECIBIR DATOS DE ARDUINO
// =====================================================

void serialEvent(Serial puerto) {

  String linea = puerto.readStringUntil('\n');

  if (linea == null) {
    return;
  }

  linea = trim(linea);

  String[] datos = split(linea, ',');

  // Formato:
  // aire,verde,trafico,potenciometro,reset

  if (datos.length != 5) {
    return;
  }

  int botonAire = int(trim(datos[0]));
  int botonVerde = int(trim(datos[1]));
  int botonTrafico = int(trim(datos[2]));

  valorPotenciometro = int(trim(datos[3]));

  int botonReset = int(trim(datos[4]));

  // Primera lectura del potenciometro.

  if (!potenciometroInicializado) {

    valorPotenciometroAnterior = valorPotenciometro;
    potenciometroInicializado = true;
  }


  // -----------------------------------------------
  // BOTON RESET
  // -----------------------------------------------

  if (botonReset == 1 && resetAnterior == 0) {

    reiniciarDatos();
  }

  resetAnterior = botonReset;


  // -----------------------------------------------
  // BOTON AIRE
  // -----------------------------------------------

  if (botonAire == 1 && botonAireAnterior == 0) {

    seleccionarIndicador(0);
  }

  botonAireAnterior = botonAire;


  // -----------------------------------------------
  // BOTON ZONAS VERDES
  // -----------------------------------------------

  if (botonVerde == 1 && botonVerdeAnterior == 0) {

    seleccionarIndicador(1);
  }

  botonVerdeAnterior = botonVerde;


  // -----------------------------------------------
  // BOTON TRAFICO
  // -----------------------------------------------

  if (botonTrafico == 1 && botonTraficoAnterior == 0) {

    seleccionarIndicador(2);
  }

  botonTraficoAnterior = botonTrafico;


  // -----------------------------------------------
  // POTENCIOMETRO
  // -----------------------------------------------

  if (
    indicadorSeleccionado != -1 &&
    abs(valorPotenciometro - valorPotenciometroAnterior) >= 4
  ) {

    int indice = zonaFila * 3 + zonaColumna;

    float nuevoValor = map(
      valorPotenciometro,
      0,
      1023,
      0,
      100
    );

    nuevoValor = constrain(nuevoValor, 0, 100);

    if (indicadorSeleccionado == 0) {

      valoresAire[indice] = nuevoValor;

    } else if (indicadorSeleccionado == 1) {

      valoresVerdes[indice] = nuevoValor;

    } else if (indicadorSeleccionado == 2) {

      valoresTrafico[indice] = nuevoValor;

    }

    actualizarCombinados();

    modoSimulacion = true;

    valorPotenciometroAnterior = valorPotenciometro;
  }
}
