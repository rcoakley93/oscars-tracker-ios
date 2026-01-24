# OscarsTracker Maestro Tests

UI tests for the OscarsTracker iOS app using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

1. **Java 17**: Required by Maestro
   ```bash
   brew install openjdk@17
   ```

2. **Maestro CLI**
   ```bash
   curl -fsSL "https://get.maestro.mobile.dev" | bash
   ```

3. **iOS Simulator**: Boot a simulator with the app installed
   ```bash
   # Boot simulator
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator

   # Build and install the app
   cd OscarsTracker
   xcodebuild -scheme OscarsTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/OscarsTracker-*/Build/Products/Debug-iphonesimulator/OscarsTracker.app
   ```

## Running Tests

### Option 1: Manual Login First (Recommended)
1. Open the app in the simulator
2. Log in with your credentials
3. Run tests:
   ```bash
   cd .maestro
   ./run-all.sh
   ```

### Option 2: Automated Login
Set environment variables for test credentials:
```bash
export MAESTRO_TEST_EMAIL="your-test@email.com"
export MAESTRO_TEST_PASSWORD="your-password"
./run-all.sh
```

### Run Individual Tests
```bash
# Ensure PATH includes Maestro
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH:$HOME/.maestro/bin"

# Run a specific test
maestro test 01-app-launch.yaml
maestro test 02-watch-plan.yaml
```

## Test Flows

| File | Description |
|------|-------------|
| `00-login.yaml` | Login flow (requires env vars) |
| `01-app-launch.yaml` | Verifies app launch and main tabs |
| `02-watch-plan.yaml` | Tests AI Auto Scheduler sheet |
| `03-what-can-i-watch.yaml` | Tests What Can I Watch feature |
| `04-add-to-plan.yaml` | Tests Add to Plan calendar UX |

## Screenshots

Test screenshots are saved to `.maestro/screenshots/`.

## Troubleshooting

**"Unable to locate a Java Runtime"**
```bash
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
```

**"Unable to launch app"**
- Make sure the app is built and installed on the simulator
- Check that the bundle ID matches: `com.oscars.tracker`

**"Dashboard is not visible"**
- The app shows a login screen first
- Log in manually or set the MAESTRO_TEST_* environment variables
