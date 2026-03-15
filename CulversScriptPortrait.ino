#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <TFT_eSPI.h>

TFT_eSPI tft = TFT_eSPI();

const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// Culver's API endpoint
const char* url = "https://www.culvers.com/api/locator/getLocations?location=53188&limit=9";

// Enhanced color palette
#define HEADER_BG     0x1E3A    // Dark blue
#define ACCENT_BLUE   0x4A9F    // Culver's blue
#define WARM_YELLOW   0xFD20    // Warm yellow
#define SOFT_WHITE    0xF7BE    // Off-white
#define LIGHT_GRAY    0x8410    // Light gray
#define FLAVOR_PINK   0xF81F    // Bright pink for flavor
#define SUCCESS_GREEN 0x07E0    // Green
#define SEPARATOR     0x6B4D    // Medium gray

// Structure to hold location data
struct LocationData {
  String name;
  String description;
  String flavorName;
  String flavorDesc;
};

LocationData locations[9]; // Array to store up to 9 locations
int locationCount = 0;
int currentLocationIndex = 0;
unsigned long lastUpdate = 0;
const unsigned long displayInterval = 12000; // 12 seconds per location
const unsigned long refreshInterval = 3000000; // 50 minutes between API calls

void setup() {
  Serial.begin(115200);

  // Initialize TFT in portrait mode
  tft.init();
  tft.setRotation(0); // Portrait mode
  tft.fillScreen(TFT_BLACK);

  // Show enhanced loading screen
  displayLoadingScreen();

  // Connect to WiFi
  WiFi.begin(ssid, password);
  int dots = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    dots = (dots + 1) % 4;
    updateLoadingDots(dots);
    Serial.print(".");
  }

  displayConnectedScreen();
  delay(1500);

  // Initial fetch
  fetchFlavorsOfTheDay();
  lastUpdate = millis();
}

void loop() {
  unsigned long currentTime = millis();

  // Cycle through locations every displayInterval
  if (currentTime - lastUpdate >= displayInterval) {
    if (locationCount > 0) {
      displayCurrentLocation();
      currentLocationIndex = (currentLocationIndex + 1) % locationCount;
    }
    lastUpdate = currentTime;
  }

  // Refresh data every refreshInterval
  static unsigned long lastRefresh = 0;
  if (currentTime - lastRefresh >= refreshInterval) {
    fetchFlavorsOfTheDay();
    lastRefresh = currentTime;
  }

  delay(100); // Small delay to prevent excessive processing
}

void displayLoadingScreen() {
  tft.fillScreen(HEADER_BG);

  // Header bar - full width at top
  tft.fillRect(0, 0, tft.width(), 50, ACCENT_BLUE);

  // Culver's title - centered for portrait
  tft.setTextSize(2);
  tft.setTextColor(TFT_WHITE);
  String title = "CULVER'S";
  int titleWidth = title.length() * 12;
  tft.setCursor((tft.width() - titleWidth) / 2, 15);
  tft.println(title);

  // Subtitle
  tft.setTextSize(1);
  tft.setTextColor(WARM_YELLOW);
  String subtitle = "Flavor Tracker";
  int subtitleWidth = subtitle.length() * 6;
  tft.setCursor((tft.width() - subtitleWidth) / 2, 80);
  tft.println(subtitle);

  // Loading message - positioned for portrait
  tft.setTextSize(1);
  tft.setTextColor(SOFT_WHITE);
  String loading = "Connecting to WiFi";
  int loadingWidth = loading.length() * 6;
  tft.setCursor((tft.width() - loadingWidth) / 2, 140);
  tft.println(loading);
}

void updateLoadingDots(int dotCount) {
  // Clear dots area
  tft.fillRect((tft.width() / 2) - 20, 160, 40, 20, HEADER_BG);

  // Draw dots
  tft.setTextSize(2);
  tft.setTextColor(ACCENT_BLUE);
  String dots = "";
  for (int i = 0; i < dotCount; i++) {
    dots += ".";
  }
  int dotsWidth = dots.length() * 12;
  tft.setCursor((tft.width() - dotsWidth) / 2, 160);
  tft.print(dots);
}

void displayConnectedScreen() {
  tft.fillRect(0, 140, tft.width(), 60, HEADER_BG);

  tft.setTextSize(1);
  tft.setTextColor(SUCCESS_GREEN);
  String connected = "Connected!";
  int connectedWidth = connected.length() * 6;
  tft.setCursor((tft.width() - connectedWidth) / 2, 145);
  tft.println(connected);

  tft.setTextSize(1);
  tft.setTextColor(LIGHT_GRAY);
  String fetching = "Fetching flavors...";
  int fetchingWidth = fetching.length() * 6;
  tft.setCursor((tft.width() - fetchingWidth) / 2, 165);
  tft.println(fetching);
}

void fetchFlavorsOfTheDay() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure(); // skip certificate validation

    HTTPClient https;
    https.begin(client, url);

    int httpCode = https.GET();
    if (httpCode > 0) {
      String payload = https.getString();
      Serial.println("API Response received");

      const size_t capacity = 50 * 1024; // adjust for large payload
      DynamicJsonDocument doc(capacity);
      DeserializationError error = deserializeJson(doc, payload);
      if (error) {
        Serial.print("JSON parse failed: ");
        Serial.println(error.f_str());
        displayEnhancedError("Failed to parse data");
        return;
      }

      JsonArray geofences = doc["data"]["geofences"].as<JsonArray>();
      locationCount = 0;

      // Store all location data
      for (JsonObject location : geofences) {
        if (locationCount >= 9) break; // Safety check

        JsonObject metadata = location["metadata"];
        locations[locationCount].name = metadata["name"].as<String>();
        locations[locationCount].description = location["description"].as<String>();
        locations[locationCount].flavorName = metadata["flavorOfDayName"].as<String>();
        locations[locationCount].flavorDesc = metadata["flavorOfTheDayDescription"].as<String>();

        Serial.println("-----------");
        Serial.println("Location " + String(locationCount + 1) + ":");
        Serial.println("Name: " + locations[locationCount].name);
        Serial.println("Description: " + locations[locationCount].description);
        Serial.println("Flavor: " + locations[locationCount].flavorName);
        Serial.println("Flavor Desc: " + locations[locationCount].flavorDesc);

        locationCount++;
      }

      Serial.println("Total locations loaded: " + String(locationCount));
      currentLocationIndex = 0; // Reset to first location

    } else {
      Serial.print("HTTP GET failed, code: ");
      Serial.println(httpCode);
      displayEnhancedError("Connection failed: " + String(httpCode));
    }
    https.end();
  } else {
    Serial.println("WiFi not connected");
    displayEnhancedError("WiFi disconnected");
  }
}

void displayCurrentLocation() {
  if (locationCount == 0) {
    displayEnhancedError("No locations found");
    return;
  }

  LocationData& loc = locations[currentLocationIndex];

  // Clear screen
  tft.fillScreen(TFT_BLACK);

  // Header bar - optimized for portrait
  tft.fillRect(0, 0, tft.width(), 40, HEADER_BG);
  tft.fillRect(0, 40, tft.width(), 3, ACCENT_BLUE);

  // Culver's logo text (centered in header for portrait)
  tft.setTextSize(2);
  tft.setTextColor(TFT_WHITE);
  String logo = "CULVER'S";
  int logoWidth = logo.length() * 12;
  tft.setCursor((tft.width() - logoWidth) / 2, 10);
  tft.print(logo);

  // Location counter (small, top right corner)
  tft.setTextSize(1);
  tft.setTextColor(WARM_YELLOW);
  String counter = String(currentLocationIndex + 1) + "/" + String(locationCount);
  int counterWidth = counter.length() * 6;
  tft.setCursor(tft.width() - counterWidth - 5, 5);
  tft.print(counter);

  int y = 55; // Start below header

  // Restaurant name (if different from description and not null/empty)
  if (loc.name.length() > 0 && loc.name != loc.description && loc.name != "null") {
    // Use larger text and wrap if needed
    y = displayWrappedText(loc.name, 8, y, WARM_YELLOW, 2, tft.width() - 16);
    y += 5;

    // Subtle underline
    tft.drawLine(10, y, tft.width() - 10, y, LIGHT_GRAY);
    y += 15;
  }

  // Location description with portrait-optimized wrapping - larger text size
  y = displayWrappedText(loc.description, 8, y, SOFT_WHITE, 2, tft.width() - 16);
  y += 15;

  // Decorative separator
  drawDecorativeSeparator(y);
  y += 20;

  // "Flavor of the Day" section header - full width for portrait
  tft.fillRect(5, y, tft.width() - 10, 30, ACCENT_BLUE);
  tft.setTextSize(1);
  tft.setTextColor(TFT_WHITE);
  String flavorHeader = "TODAY'S FLAVOR";
  int headerWidth = flavorHeader.length() * 6;
  tft.setCursor((tft.width() - headerWidth) / 2, y + 10);
  tft.print(flavorHeader);
  y += 40;

  // Flavor name - centered and sized for portrait
  tft.setTextSize(2);
  tft.setTextColor(FLAVOR_PINK);

  // Check if flavor name needs wrapping for narrow portrait width
  int flavorEstWidth = loc.flavorName.length() * 12;
  if (flavorEstWidth > tft.width() - 10) {
    // Use word wrapping for long flavor names
    y = displayWrappedText(loc.flavorName, 8, y, FLAVOR_PINK, 2, tft.width() - 16);
  } else {
    // Center the flavor name
    int flavorX = (tft.width() - flavorEstWidth) / 2;
    tft.setCursor(flavorX, y);
    tft.println(loc.flavorName);
    y += 25;
  }

  y += 10;

  // Flavor description in styled box - optimized for portrait height
  int boxY = y;
  int availableHeight = tft.height() - boxY - 15;
  int boxHeight = min(availableHeight, 120);

  // Background box for flavor description
  tft.fillRect(5, boxY, tft.width() - 10, boxHeight, 0x0841); // Very dark blue
  tft.drawRect(5, boxY, tft.width() - 10, boxHeight, SEPARATOR);

  // Flavor description text with portrait-friendly wrapping
  displayWrappedText(loc.flavorDesc, 10, boxY + 8, 0xAD75, 1, tft.width() - 20); // Light blue text

  // Bottom accent line
  tft.drawLine(0, tft.height() - 2, tft.width(), tft.height() - 2, ACCENT_BLUE);
}

int displayWrappedText(String text, int x, int y, uint16_t color, int textSize, int maxWidth) {
  tft.setTextSize(textSize);
  tft.setTextColor(color);

  // Calculate characters per line for portrait mode (narrower width)
  int charsPerLine = maxWidth / (6 * textSize);
  int currentY = y;
  int startIndex = 0;

  while (startIndex < text.length()) {
    int endIndex = min((int)text.length(), startIndex + charsPerLine);
    String line = text.substring(startIndex, endIndex);

    // Try to break at word boundaries
    if (endIndex < text.length()) {
      int lastSpace = line.lastIndexOf(' ');
      if (lastSpace > charsPerLine * 0.6) { // Adjusted for portrait
        line = line.substring(0, lastSpace);
        startIndex += lastSpace + 1;
      } else {
        startIndex = endIndex;
      }
    } else {
      startIndex = text.length();
    }

    tft.setCursor(x, currentY);
    tft.print(line);
    currentY += 6 + (textSize * 6); // Adjusted line height for portrait

    // Portrait-friendly screen boundary check
    if (currentY > tft.height() - 25) break;
  }

  return currentY;
}

void drawDecorativeSeparator(int y) {
  // Central diamond - adjusted for portrait width
  int centerX = tft.width() / 2;
  tft.fillRect(centerX - 2, y - 2, 4, 4, ACCENT_BLUE);

  // Side lines - shorter for portrait
  tft.drawLine(15, y, centerX - 6, y, SEPARATOR);
  tft.drawLine(centerX + 6, y, tft.width() - 15, y, SEPARATOR);
}

void displayEnhancedError(String message) {
  tft.fillScreen(TFT_BLACK);

  // Error header - full width for portrait
  tft.fillRect(0, 0, tft.width(), 40, 0x8000); // Dark red
  tft.setTextSize(2);
  tft.setTextColor(TFT_WHITE);
  String errorTitle = "ERROR";
  int titleWidth = errorTitle.length() * 12;
  tft.setCursor((tft.width() - titleWidth) / 2, 10);
  tft.print(errorTitle);

  // Error icon (simple exclamation) - centered for portrait
  int iconX = tft.width() / 2 - 2;
  tft.fillRect(iconX, 60, 4, 15, TFT_RED);
  tft.fillRect(iconX, 80, 4, 4, TFT_RED);

  // Error message - wrapped for portrait width
  tft.setTextSize(1);
  tft.setTextColor(SOFT_WHITE);
  displayWrappedText(message, 10, 100, SOFT_WHITE, 1, tft.width() - 20);

  // Retry indicator
  tft.setTextSize(1);
  tft.setTextColor(LIGHT_GRAY);
  String retry = "Retrying in 50 minutes...";
  int retryWidth = retry.length() * 6;
  int retryX = max(5, (tft.width() - retryWidth) / 2);
  tft.setCursor(retryX, 140);
  tft.print(retry);
}
