import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nehhdc_app/IOT_Screen/DeviceStatus_Screen.dart';
import 'package:quickalert/quickalert.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;

class IOTDevice_Scan extends StatefulWidget {
  @override
  State<IOTDevice_Scan> createState() => _IOTDevice_ScanState();
}

class _IOTDevice_ScanState extends State<IOTDevice_Scan> {
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool isScanCompleted = false;
  bool isConnected = false;
  MobileScannerController cameraController = MobileScannerController();
  String? Deviceresult;
  flutterBlue.BluetoothDevice? connectedDevice;

  void closeScreen() {
    setState(() {
      isScanCompleted = false;
    });
  }

  @override
  void initState() {
    super.initState();
    closeScreen();
    startScanner();
  }

  void startScanner() {
    cameraController.start();
  }

  void stopScanner() {
    cameraController.stop();
  }

  void showInvalidBarcodeMessage(BuildContext context) {
    QuickAlert.show(
      context: context,
      title: "Device Error",
      type: QuickAlertType.error,
      text: "Please scan a valid QR",
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        setState(() {
          isScanCompleted = false;
        });
        startScanner();
      },
    );
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      flutterBlue.FlutterBlue flutterBlueInstance =
          flutterBlue.FlutterBlue.instance;

      flutterBlueInstance.scanResults
          .listen((List<flutterBlue.ScanResult> results) {
        for (var result in results) {
          if (result.device.id.id == deviceId) {
            flutterBlueInstance.stopScan();
            connect(result.device);
            return;
          }
        }
      });

      if (!isConnected) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Device Not Found'),
            content: Text('No device found for the scanned QR code.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isScanCompleted = false;
                    startScanner();
                  });
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> connect(flutterBlue.BluetoothDevice device) async {
    try {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: "Please Wait",
        text: "Connecting to the device...",
      );

      await device.connect();

      List<flutterBlue.BluetoothService> services =
          await device.discoverServices();

      flutterBlue.BluetoothService customService = services.firstWhere(
        (service) =>
            service.uuid.toString() == 'f3641400-00b0-4240-ba50-05ca45bf8abc',
        orElse: () => throw Exception('Custom service with UUID not found'),
      );

      flutterBlue.BluetoothCharacteristic customCharacteristic =
          customService.characteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid.toString() == 'f3641401-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641402-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641403-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641404-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641405-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641406-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641407-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641408-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f3641409-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f364140A-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f364140B-00b0-4240-ba50-05ca45bf8abc' ||
            characteristic.uuid.toString() ==
                'f364140C-00b0-4240-ba50-05ca45bf8abc',
        orElse: () =>
            throw Exception('Custom characteristic with UUID not found'),
      );

      setState(() {
        isConnected = true;
        connectedDevice = device;
      });
      Navigator.of(context).pop();

      _navigateToDeviceStatusScreen(
          device, customCharacteristic, customService);
    } catch (e) {
      print('Error connecting to device: $e');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToDeviceStatusScreen(
    flutterBlue.BluetoothDevice device,
    flutterBlue.BluetoothCharacteristic characteristic,
    flutterBlue.BluetoothService service,
  ) {
    if (isConnected) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Device_Status(
            device: device,
            characteristic: characteristic,
            service: service,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff022a72),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.white,
        ),
        title: Text(
          "IOT Device Scan",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: (barcodeCapture) async {
                      if (!isScanCompleted) {
                        setState(() {
                          isScanCompleted = true;
                        });
                        stopScanner();
                        final List<Barcode> barcodes = barcodeCapture.barcodes;
                        String barcode = barcodes.isNotEmpty
                            ? barcodes.first.rawValue ?? '---'
                            : '---';

                        if (barcode.length != 17) {
                          showInvalidBarcodeMessage(context);
                          return;
                        }
                        if (barcode.isNotEmpty) {
                          if (isConnected && connectedDevice != null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Device Already Connected'),
                                content: Text(
                                    'The device ${connectedDevice!.name} is already connected.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          await connectToDevice(barcode);
                        }
                      }
                    },
                  ),
                  QRScannerOverlay(
                    overlayColor: Colors.black26,
                    borderColor: Colors.white,
                    borderRadius: 10,
                    borderStrokeWidth: 5,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "|Scan properly to see results|",
                  style: TextStyle(
                    color: Color(0xff022a72),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
