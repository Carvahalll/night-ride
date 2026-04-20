#include <Keyboard.h>

// --- Pin Configuration ---
const int PIN_BRAKE_LEFT  = 3;
const int PIN_BRAKE_RIGHT = 2;

// --- Debounce ---
const unsigned long DEBOUNCE_MS = 50;

bool leftPressed  = false;
bool rightPressed = false;

unsigned long lastDebounceLeft  = 0;
unsigned long lastDebounceRight = 0;

void setup() {
  pinMode(PIN_BRAKE_LEFT,  INPUT_PULLUP); // Wire brake between pin 2 and GND
  pinMode(PIN_BRAKE_RIGHT, INPUT_PULLUP); // Wire brake between pin 3 and GND
  Keyboard.begin();
}

void loop() {
  unsigned long now = millis();

  // --- LEFT BRAKE ---
  bool leftReading = (digitalRead(PIN_BRAKE_LEFT) == LOW); // LOW = pressed (pull-up)

  if (leftReading != leftPressed && (now - lastDebounceLeft) > DEBOUNCE_MS) {
    lastDebounceLeft = now;
    leftPressed = leftReading;

    if (leftPressed)  Keyboard.press(KEY_LEFT_ARROW);
    else              Keyboard.release(KEY_LEFT_ARROW);
  }

  // --- RIGHT BRAKE ---
  bool rightReading = (digitalRead(PIN_BRAKE_RIGHT) == LOW);

  if (rightReading != rightPressed && (now - lastDebounceRight) > DEBOUNCE_MS) {
    lastDebounceRight = now;
    rightPressed = rightReading;

    if (rightPressed)  Keyboard.press(KEY_RIGHT_ARROW);
    else               Keyboard.release(KEY_RIGHT_ARROW);
  }
}
