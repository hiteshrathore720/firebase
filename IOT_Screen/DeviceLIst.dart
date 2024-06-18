import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:nehhdc_app/IOT_Screen/DeviceStatus_Screen.dart';
import 'package:nehhdc_app/IOT_Screen/IOTDevice_Scan.dart';
import 'package:nehhdc_app/Setting_Screen/Setting_Screen.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({Key? key}) : super(key: key);

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  List<ScanResult> devices = [];
  bool isScanning = false;
  bool isBluetoothOn = true;
  bool isConnected = false;
  int? connectedDeviceIndex;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth(context);
  }

  Future<void> _initBluetooth(BuildContext context) async {
    FlutterBlue flutterBlue = FlutterBlue.instance;

    flutterBlue.state.listen((BluetoothState state) {
      setState(() {
        isBluetoothOn = state == BluetoothState.on;
        if (isBluetoothOn) {
          startScan();
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  "Bluetooth Scanner",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  "Turn on Bluetooth to scan nearby devices.",
                  style: TextStyle(fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Device List',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isScanning ? stopScan : startScan,
            child: Text(
              isScanning ? 'STOP SCANNING' : 'SCAN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(ColorVal),
      ),
      body: Column(
        children: [
          if (!isBluetoothOn)
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Colors.red,
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bluetooth is disabled",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                      onPressed: () {
                        _enableBluetooth(context);
                      },
                      child: Text(
                        "Enable",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ))
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                bool hasDesiredService = devices[index]
                    .advertisementData
                    .serviceUuids
                    .contains('f3641400-00b0-4240-ba50-05ca45bf8abc');

                if (!hasDesiredService) {
                  return SizedBox.shrink();
                }

                bool isConnectedToDevice =
                    isConnected && connectedDeviceIndex == index;

                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          Icons.bluetooth,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.cyan,
                      ),
                      title: Text(
                        devices[index].device.name,
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        devices[index].device.id.toString(),
                        style: TextStyle(fontSize: 13),
                      ),
                      trailing: Container(
                        width: 120,
                        child: InkWell(
                          child: Row(
                            children: [
                              Container(
                                height: 30,
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: isConnectedToDevice
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                child: Center(
                                  child: isConnecting &&
                                          connectedDeviceIndex == index
                                      ? Text(
                                          "Please wait...",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : Text(
                                          isConnectedToDevice
                                              ? "Connected"
                                              : "Connect",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          onTap: isConnected || isConnectedToDevice
                              ? null
                              : () async {
                                  setState(() {
                                    connectedDeviceIndex = index;
                                    isConnecting = true;
                                  });
                                  await connectToDevice(
                                      context, devices[index]);
                                },
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Divider(),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(ColorVal),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => IOTDevice_Scan(),
            ),
          );
        },
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> startScan() async {
    setState(() {
      devices.clear();
      isScanning = true;
    });

    FlutterBlue.instance.scanResults.listen((List<ScanResult> scanResults) {
      setState(() {
        devices = scanResults;
      });
    });

    await FlutterBlue.instance.startScan();
  }

  void stopScan() {
    setState(() {
      isScanning = false;
    });
    FlutterBlue.instance.stopScan();
  }

  Future<void> connectToDevice(
      BuildContext context, ScanResult scanResult) async {
    BluetoothDevice device = scanResult.device;
    try {
      await device.connect();
      setState(() {
        isConnected = true;
        isConnecting = false;
      });

      await Future.delayed(Duration(seconds: 1));

      List<BluetoothService> services = await device.discoverServices();

      BluetoothService customService = services.firstWhere(
        (service) =>
            service.uuid.toString() == 'f3641400-00b0-4240-ba50-05ca45bf8abc',
        orElse: () => throw Exception('Custom service with UUID not found'),
      );

      if (customService != '') {
        BluetoothCharacteristic customCharacteristic =
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

        if (customCharacteristic != '') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Device_Status(
                device: device,
                characteristic: customCharacteristic,
                service: customService,
              ),
            ),
          );
          setState(() {
            isConnected = true;
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Custom characteristic not found in the service.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Custom service not found on the device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isConnected = false;
        isConnecting = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to connect to the device. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    device.state.listen((BluetoothDeviceState state) {
      if (state == BluetoothDeviceState.disconnected) {
        setState(() {
          isConnected = false;
          connectedDeviceIndex = null;
        });
      }
    });
  }

  void _enableBluetooth(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            "An app wants to turn on Bluetooth.",
            style: TextStyle(fontSize: 12),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10.0),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    //       FlutterBlue flutterBlue = FlutterBlue.instance;
                  },
                  child: Text('Yes'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('No'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
