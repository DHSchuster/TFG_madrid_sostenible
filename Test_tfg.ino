
const int botonAire = 2;
const int botonVerde = 3;
const int botonTrafico = 4;
const int botonReset = 5;

const int potenciometro = A2;

void setup() {
  Serial.begin(9600);

  pinMode(botonAire, INPUT_PULLUP);
  pinMode(botonVerde, INPUT_PULLUP);
  pinMode(botonTrafico, INPUT_PULLUP);
  pinMode(botonReset, INPUT_PULLUP);
}

void loop() {
  int aire = digitalRead(botonAire) == LOW ? 1 : 0;
  int verde = digitalRead(botonVerde) == LOW ? 1 : 0;
  int trafico = digitalRead(botonTrafico) == LOW ? 1 : 0;
  int reset = digitalRead(botonReset) == LOW ? 1 : 0;

  int pot = analogRead(potenciometro);

  Serial.print(aire);
  Serial.print(",");
  Serial.print(verde);
  Serial.print(",");
  Serial.print(trafico);
  Serial.print(",");
  Serial.print(pot);
  Serial.print(",");
  Serial.println(reset);

  delay(100);
}
