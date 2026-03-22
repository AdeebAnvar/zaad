# Thermal printing – USB, LAN, Bluetooth

The app prints to thermal printers over **USB**, **LAN (Wi‑Fi)**, and **Bluetooth (BLE)**. Support and permissions vary by platform.

## Platform support

| Connection | Android | iOS | Windows |
|------------|---------|-----|---------|
| **LAN (Wi‑Fi)** | ✅ | ✅ | ✅ |
| **Bluetooth (BLE)** | ✅ | ✅ | ✅ |
| **USB** | ✅ | ❌ * | ✅ |

\* iOS does not support USB host for external printers; use LAN or Bluetooth on iPhone/iPad.

## Permissions and setup

### Android

**Manifest** (`android/app/src/main/AndroidManifest.xml`) already includes:

- `INTERNET`, `ACCESS_NETWORK_STATE` – LAN printers
- `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` – Bluetooth
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` – BLE scan (Android &lt; 12)
- `uses-feature android.hardware.usb.host` – USB (optional)

**Runtime (Android 12+):** The app requests **Bluetooth scan** and **Bluetooth connect** when you tap “Scan printers” in Kitchen Printers. If you previously denied them, open **Settings → Apps → Pos → Permissions** and allow Bluetooth, then scan again.

### iOS

**Info.plist** already includes:

- `NSBluetoothAlwaysUsageDescription` – Bluetooth for thermal printers
- `NSBluetoothPeripheralUsageDescription` – same
- `NSAppTransportSecurity` with local networking – LAN printers

The system will prompt for Bluetooth when you first scan. Allow it so the app can discover BLE printers.

### Windows

- **LAN:** No extra setup.
- **Bluetooth:** Use a Bluetooth 4.0+ (BLE) adapter; pair the printer in Windows first if needed.
- **USB:** Install the printer’s driver (e.g. [XPrinter drivers](https://www.xprintertech.com/drivers-2.html) or the manufacturer’s). Windows may report USB printers with **productId = N/A**; the app handles that and uses the printer name.

## Troubleshooting

1. **“Bluetooth permission is needed”** – Grant Bluetooth (and, on Android, location if asked) in system settings for the app, then try “Scan printers” again.
2. **USB printer not in list / null error** – On Windows, ensure the printer driver is installed and the device appears in “Devices and printers”. Rescan after that.
3. **BLE “Unreachable”** – Turn the printer on, keep it in range, and ensure it isn’t connected to another app or device.
4. **LAN printer not found** – Check the printer’s IP and port (often 9100). Ensure the phone/tablet/PC is on the same network as the printer.
