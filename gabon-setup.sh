#!/bin/bash

# GabonConnect Phase 2 Setup & Run Script
# Usage: ./gabon-setup.sh [command]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 GabonConnect Phase 2 Setup${NC}"
echo "======================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter SDK first.${NC}"
    echo "Download from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"

# Get pub get
echo -e "\n${YELLOW}📦 Installing dependencies...${NC}"
flutter pub get

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️ .env not found. Creating from .env.example${NC}"
    cp .env.example .env
    echo -e "${YELLOW}📝 Edit .env with your Twilio credentials:${NC}"
    echo "   TWILIO_ACCOUNT_SID=ACxxxxxxxx..."
    echo "   TWILIO_AUTH_TOKEN=xxxxxxxx..."
    echo "   TWILIO_PHONE_NUMBER=+1234567890"
fi

# Optional: Run analysis
if [ "$1" = "analyze" ]; then
    echo -e "\n${YELLOW}🔍 Running analysis...${NC}"
    flutter analyze
fi

# Optional: Run tests
if [ "$1" = "test" ]; then
    echo -e "\n${YELLOW}🧪 Running tests...${NC}"
    flutter test
fi

# Default: Run app
echo -e "\n${GREEN}▶️ Starting GabonConnect...${NC}"
flutter run

echo -e "${GREEN}✅ Done!${NC}"
