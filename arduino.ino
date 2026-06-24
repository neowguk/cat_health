// #include <SPI.h>
// #include <MFRC522.h>
// #include "HX711.h"
// #include <WiFiS3.h>
// #include <ArduinoMqttClient.h>
// #include <ArduinoJson.h>

// // ---------------- WiFi / MQTT ----------------
// const char* WIFI_SSID = "qwerty";
// const char* WIFI_PASS = "tkagh6a7ab";

// const char* MQTT_BROKER = "48c3ba6414d7464383ec7f469b55003d.s1.eu.hivemq.cloud";
// const int   MQTT_PORT   = 8883;
// const char* MQTT_USER   = "tkagh6a7ab";
// const char* MQTT_PASS   = "Ghkdxowk45@";
// const char* CLIENT_ID   = "uno_r4_cat_tower";

// const char* TOPIC_STATUS = "cat_tower/status";
// const char* TOPIC_STATE  = "cat_tower/state";

// WiFiSSLClient sslClient;
// MqttClient mqttClient(sslClient);

// // ---------------- RFID ----------------
// #define SS_PIN 10
// #define RST_PIN 9
// MFRC522 rfid(SS_PIN, RST_PIN);

// // ---------------- HX711 ----------------
// #define DT 3
// #define SCK 2
// HX711 scale;
// float calibration_factor = -350;

// // ---------------- 설정값 ----------------
// const int STABLE_SAMPLE_COUNT = 5;
// const float STABLE_RANGE = 30.0;
// const int FINAL_AVG_COUNT = 10;
// const int SAMPLE_INTERVAL = 150;
// const unsigned long STABLE_TIMEOUT = 10000;
// const unsigned long RFID_REINIT_TIMEOUT = 10000;
// const unsigned long WIFI_RETRY_INTERVAL = 5000;
// const unsigned long MQTT_RETRY_INTERVAL = 5000;

// // ---------------- 히터 타이머 ----------------
// bool heaterOn = false;
// unsigned long heaterStartTime = 0;
// const unsigned long HEATER_DURATION = 3600000UL; // 1시간

// unsigned long lastRFIDOkTime = 0;
// unsigned long lastWifiRetry = 0;
// unsigned long lastMqttRetry = 0;

// bool scaleAwake = false;
// float recentValues[STABLE_SAMPLE_COUNT];
// int recentIndex = 0;
// bool bufferFilled = false;

// // ---------------- 버퍼 ----------------
// void resetRecentBuffer() {
//   recentIndex = 0;
//   bufferFilled = false;
//   for (int i = 0; i < STABLE_SAMPLE_COUNT; i++) recentValues[i] = 0;
// }

// void addRecentValue(float value) {
//   recentValues[recentIndex] = value;
//   recentIndex++;
//   if (recentIndex >= STABLE_SAMPLE_COUNT) {
//     recentIndex = 0;
//     bufferFilled = true;
//   }
// }

// float getRecentRange() {
//   int count = bufferFilled ? STABLE_SAMPLE_COUNT : recentIndex;
//   if (count < STABLE_SAMPLE_COUNT) return 999999.0;
//   float minVal = recentValues[0], maxVal = recentValues[0];
//   for (int i = 1; i < count; i++) {
//     if (recentValues[i] < minVal) minVal = recentValues[i];
//     if (recentValues[i] > maxVal) maxVal = recentValues[i];
//   }
//   return maxVal - minVal;
// }

// // ---------------- HX711 ----------------
// void wakeScale() {
//   if (!scaleAwake) {
//     scale.power_up();
//     delay(200);
//     scale.set_scale(calibration_factor);
//     scale.tare();
//     delay(200);
//     scaleAwake = true;
//     Serial.println("로드셀 활성화");
//   }
// }

// void sleepScale() {
//   if (scaleAwake) {
//     scale.power_down();
//     scaleAwake = false;
//     Serial.println("로드셀 비활성화");
//   }
// }

// float readWeightOnce() {
//   if (!scaleAwake) return 9999999.0;
//   if (!scale.is_ready()) return 9999999.0;
//   return scale.get_units(10);
// }

// bool waitForStableWeight() {
//   resetRecentBuffer();
//   unsigned long startTime = millis();
//   while (millis() - startTime < STABLE_TIMEOUT) {
//     mqttClient.poll();
//     float value = readWeightOnce();
//     if (value == 9999999.0) { delay(200); continue; }
//     addRecentValue(value);
//     Serial.print("현재 무게값: "); Serial.print(value, 2); Serial.println(" g");
//     if (bufferFilled) {
//       float range = getRecentRange();
//       Serial.print("최근 변화폭: "); Serial.print(range, 2); Serial.println(" g");
//       if (range <= STABLE_RANGE) return true;
//     }
//     delay(SAMPLE_INTERVAL);
//   }
//   return false;
// }

// float measureFinalAverage(int count) {
//   float sum = 0; int validCount = 0;
//   for (int i = 0; i < count; i++) {
//     mqttClient.poll();
//     float value = readWeightOnce();
//     if (value != 9999999.0) { sum += value; validCount++; }
//     delay(SAMPLE_INTERVAL);
//   }
//   if (validCount == 0) return 0;
//   return sum / validCount;
// }

// // ---------------- RFID ----------------
// String getUidString() {
//   String uid = "";
//   for (byte i = 0; i < rfid.uid.size; i++) {
//     if (rfid.uid.uidByte[i] < 0x10) uid += "0";
//     uid += String(rfid.uid.uidByte[i], HEX);
//   }
//   uid.toUpperCase();
//   return uid;
// }

// void printUID() {
//   Serial.print("UID : ");
//   for (byte i = 0; i < rfid.uid.size; i++) {
//     if (rfid.uid.uidByte[i] < 0x10) Serial.print("0");
//     Serial.print(rfid.uid.uidByte[i], HEX);
//     Serial.print(" ");
//   }
//   Serial.println();
// }

// void reinitRFID() {
//   Serial.println("RFID 응답 없음 -> RC522 재초기화");
//   rfid.PCD_Reset(); delay(50);
//   rfid.PCD_Init(); delay(10);
//   lastRFIDOkTime = millis();
//   Serial.println("RC522 재초기화 완료");
// }

// // ---------------- WiFi / MQTT ----------------
// void connectWiFi() {
//   if (WiFi.status() == WL_CONNECTED) return;
//   Serial.print("WiFi 연결 중: "); Serial.println(WIFI_SSID);
//   while (WiFi.begin(WIFI_SSID, WIFI_PASS) != WL_CONNECTED) {
//     Serial.println("WiFi 연결 실패, 3초 후 재시도");
//     delay(3000);
//   }
//   Serial.println("WiFi 연결 성공");
//   Serial.print("IP: "); Serial.println(WiFi.localIP());
// }

// void connectMQTT() {
//   if (mqttClient.connected()) return;
//   mqttClient.setId(CLIENT_ID);
//   mqttClient.setUsernamePassword(MQTT_USER, MQTT_PASS);
//   mqttClient.setKeepAliveInterval(20);
//   mqttClient.setConnectionTimeout(5000);
//   Serial.print("MQTT 연결 중: "); Serial.println(MQTT_BROKER);
//   while (!mqttClient.connect(MQTT_BROKER, MQTT_PORT)) {
//     Serial.print("MQTT 연결 실패, error = ");
//     Serial.println(mqttClient.connectError());
//     delay(5000);
//   }
//   Serial.println("MQTT 연결 성공");
// }

// void ensureConnections() {
//   if (WiFi.status() != WL_CONNECTED) {
//     if (millis() - lastWifiRetry >= WIFI_RETRY_INTERVAL) {
//       lastWifiRetry = millis(); connectWiFi();
//     }
//     return;
//   }
//   if (!mqttClient.connected()) {
//     if (millis() - lastMqttRetry >= MQTT_RETRY_INTERVAL) {
//       lastMqttRetry = millis(); connectMQTT();
//     }
//     return;
//   }
//   mqttClient.poll();
// }

// // ---------------- Publish ----------------
// bool publishStatus(const String& uid) {
//   if (!mqttClient.connected()) return false;
//   StaticJsonDocument<128> doc;
//   doc["rfid"] = uid;
//   String payload; serializeJson(doc, payload);
//   mqttClient.beginMessage(TOPIC_STATUS);
//   mqttClient.print(payload);
//   bool ok = mqttClient.endMessage();
//   Serial.print("status publish: "); Serial.println(ok ? "성공" : "실패");
//   Serial.println(payload);
//   return ok;
// }

// bool publishState(float weightGram, bool heater) {
//   if (!mqttClient.connected()) return false;
//   StaticJsonDocument<128> doc;
//   doc["weight"] = weightGram / 1000.0;
//   doc["heater"] = heater;
//   String payload; serializeJson(doc, payload);
//   mqttClient.beginMessage(TOPIC_STATE, payload.length(), true, 1);
//   mqttClient.print(payload);
//   bool ok = mqttClient.endMessage();
//   Serial.print("state publish: "); Serial.println(ok ? "성공" : "실패");
//   Serial.println(payload);
//   return ok;
// }

// // ---------------- setup / loop ----------------
// void setup() {
//   Serial.begin(115200);
//   delay(1500);

//   SPI.begin();
//   rfid.PCD_Init();
//   delay(4);

//   scale.begin(DT, SCK);
//   scale.set_scale();
//   scale.tare();
//   scale.set_scale(calibration_factor);
//   scale.power_down();
//   scaleAwake = false;

//   lastRFIDOkTime = millis();
//   connectWiFi();
//   connectMQTT();

//   Serial.println("시스템 준비 완료");
//   Serial.println("RFID 태그를 대세요.");
// }

// void loop() {
//   ensureConnections();

//   // 히터 1시간 후 자동 OFF
//   if (heaterOn && millis() - heaterStartTime >= HEATER_DURATION) {
//     heaterOn = false;
//     publishState(0, false);
//     Serial.println("히터 자동 OFF (1시간 경과)");
//   }

//   if (millis() - lastRFIDOkTime > RFID_REINIT_TIMEOUT) {
//     reinitRFID();
//   }

//   if (!rfid.PICC_IsNewCardPresent()) { delay(20); return; }
//   if (!rfid.PICC_ReadCardSerial()) { delay(20); return; }

//   lastRFIDOkTime = millis();
//   Serial.println("RFID 인식됨");
//   printUID();

//   String uid = getUidString();
//   publishStatus(uid);

//   wakeScale();
//   Serial.println("2초 후 무게 측정 시작...");
//   delay(2000);
//   Serial.println("무게 안정화 대기 중...");

//   bool isStable = waitForStableWeight();
//   float finalAvg = measureFinalAverage(FINAL_AVG_COUNT);

//   Serial.print("최종 평균 무게: ");
//   Serial.print(finalAvg, 2);
//   Serial.println(" g");

//   // 히터 ON + 1시간 타이머 시작
//   heaterOn = true;
//   heaterStartTime = millis();
//   publishState(finalAvg, true);
//   Serial.println("히터 ON (1시간 카운트 시작)");

//   sleepScale();
//   rfid.PICC_HaltA();
//   rfid.PCD_StopCrypto1();

//   Serial.println("-------------------------");
//   Serial.println("다음 RFID 태그를 기다립니다.");
//   delay(1000);
// }

