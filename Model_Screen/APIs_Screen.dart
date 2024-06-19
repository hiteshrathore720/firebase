import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nehhdc_app/Screen/Add_Product.dart';
import 'package:nehhdc_app/Screen/Bottom_Screen.dart';
import 'package:nehhdc_app/Screen/Product_List.dart';
import 'package:nehhdc_app/Setting_Screen/Directory_Screen.dart';
import 'package:nehhdc_app/Setting_Screen/Setting_Screen.dart';
import 'package:nehhdc_app/Setting_Screen/Static_Verible';
import 'package:path/path.dart';
import 'package:quickalert/quickalert.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;

class Temp {
  final String tempurl;
  int status;

  Temp({required this.tempurl, required this.status});
}

String getQrValue(String url) {
  Uri uri = Uri.parse(url);

  staticverible.qrval = uri.queryParameters['ID'].toString();

  return staticverible.qrval;
}

class TempAPIs {
  final String apiUrl = staticverible.temqr + "/QRcheck.aspx/GetData";

  Future<List<Temp>> fetchTemp(
      BuildContext context, String url, VoidCallback onDismiss) async {
    String qrval1 = getQrValue(url);

    try {
      plaesewaitmassage(context);
      final Map<String, dynamic> requestBody = {"qrvalue": qrval1};
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);
          if (dataMap['statuscode'] == "1") {
            String message = dataMap['message'];
            int statusCode = int.parse(dataMap['statuscode']);
            staticverible.statuscode = statusCode;
            Temp temp = Temp(tempurl: message, status: statusCode);
            Navigator.of(context).pop();
            return [temp];
          } else if (dataMap['statuscode'] == "2") {
            String errorMessage = dataMap['message'];
            Navigator.of(context).pop();
            QuickAlert.show(
              context: context,
              type: QuickAlertType.info,
              title: '',
              text: errorMessage,
              onConfirmBtnTap: () {
                Navigator.of(context).pop();
                onDismiss();
              },
            );
          }
        } else {
          throw Exception('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        Navigator.of(context).pop();
        throw Exception('Failed to load QR Scan');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      Navigator.of(context).pop();
      throw Exception('Failed to load QR Scan: $e');
    }

    return [];
  }
}

class Login {
  final String username;
  final String password;
  final String tempmass;
  int status;

  Login({
    required this.username,
    required this.password,
    required this.tempmass,
    required this.status,
  });
}

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'MST_URL';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initializeDatabase();
    return _database!;
  }

  static Future<Database> initializeDatabase() async {
    Directory? externalDirectory = await getAndroidMediaDirectory();
    if (externalDirectory == null) {
      throw Exception('External storage directory not found');
    }

    final String folderPath = join(externalDirectory.path, 'Database');
    final Directory folder = Directory(folderPath);
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }

    final String dbPath = join(folder.path, 'ssbi.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  static void _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY,
        name TEXT,
        url TEXT,
        username TEXT,
        password TEXT
      )
    ''');
  }

  static Future<void> _upgradeDb(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $tableName ADD COLUMN username TEXT;
      ''');
      await db.execute('''
        ALTER TABLE $tableName ADD COLUMN password TEXT;
      ''');
    }
  }

  static Future<int> insertUrl({
    required String url,
    required String username,
    required String password,
  }) async {
    final Database db = await database;

    return await db.insert(tableName, {
      'url': url,
      'username': username,
      'password': password,
    });
  }

  static Future<int> updateUrl({
    required int id,
    required String url,
    required String username,
    required String password,
  }) async {
    final Database db = await database;

    return await db.update(
      tableName,
      {
        'url': url,
        'username': username,
        'password': password,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAll() async {
    final Database db = await database;
    await db.delete(tableName);
  }

  static Future<void> updateCredentialsToNull() async {
    final Database db = await database;
    await db.update(
      tableName,
      {
        'username': null,
        'password': null,
      },
      where: '1=1',
    );
  }

  static Future<List<Map<String, dynamic>>?> getUrls() async {
    final Database db = await database;
    List<Map<String, dynamic>>? urls;

    try {
      urls = await db.query(tableName);
    } catch (e) {
      print('Error retrieving data: $e');
      logError('$e');
    }

    return urls;
  }

  static Future<void> clearDatabase() async {
    Directory? externalDirectory = await getAndroidMediaDirectory();
    if (externalDirectory != null) {
      final String folderPath = join(externalDirectory.path, 'Database');
      final Directory folder = Directory(folderPath);
      if (folder.existsSync()) {
        folder.deleteSync(recursive: true);
      }
    }
  }
}

// Registered Mail
class Tempmail {
  final String tempurl;

  Tempmail({required this.tempurl});
}

class RegisteredAPIs {
  final String regiApis =
      staticverible.temqr + '/profilestatus.aspx/checkuserstatus';

  Future<Tempmail> fetchRegisteredMail(String registeredMail) async {
    try {
      final Map<String, dynamic> requestBody = {"emailid": registeredMail};
      final response = await http.post(
        Uri.parse(regiApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);

          String message = dataMap['message'];
          return Tempmail(tempurl: message);
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load Registered Mail. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load Registered Mail: $e');
    }
  }
}

// Forget Password
class Tempforget {
  final String tempmass;

  Tempforget({required this.tempmass});
}

class Forgetapis {
  final String forgetApis =
      staticverible.temqr + '/forgetpassword.aspx/forgotpassword';

  Future<Tempforget> Fetchforget(String userid, String email) async {
    try {
      final Map<String, dynamic> requestBody = {
        "userid": userid,
        'emailid': email
      };
      final response = await http.post(
        Uri.parse(forgetApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);

          String message = dataMap['message'];
          return Tempforget(tempmass: message);
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load Forget Password HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load Forget Password: $e');
    }
  }
}

String getQrValue1(String url) {
  Uri uri = Uri.parse(url);

  String? qrValue = uri.queryParameters['ID'];

  return qrValue ?? '';
}

Future<String> UploadFilesData(
  BuildContext context,
  String qrcodevalue,
  String productname,
  String weavername,
  String? imagePath,
  String? compressedVideoPath,
  String deviceid,
  String dimision,
  String dyestatus,
  String naturedays,
  String weavertype,
  String yerntype,
  String yarncount,
  String loomtype,
) async {
  String responseMessage = "";

  dimision = dimision.trim().isEmpty || dimision.trim() == ''
      ? 'ALL'
      : dimision.trim();
  dyestatus = dyestatus.trim().isEmpty || dyestatus.trim() == ''
      ? 'ALL'
      : dyestatus.trim();
  naturedays = naturedays.trim().isEmpty || naturedays.trim() == ''
      ? 'ALL'
      : naturedays.trim();
  weavertype = weavertype.trim().isEmpty || weavertype.trim() == ''
      ? 'ALL'
      : weavertype.trim();
  yerntype = yerntype.trim().isEmpty || yerntype.trim() == ''
      ? 'ALL'
      : yerntype.trim();
  yarncount = yarncount.trim().isEmpty || yarncount.trim() == ''
      ? 'ALL'
      : yarncount.trim();
  loomtype = loomtype.trim().isEmpty || loomtype.trim() == ''
      ? 'ALL'
      : loomtype.trim();

  try {
    final String apiurl =
        staticverible.temqr + "/UploadService.asmx/UploadFiles";
    var request = http.MultipartRequest('POST', Uri.parse(apiurl));

    request.fields['product'] = productname;
    request.fields['weaver'] = weavername;
    request.fields['devicecode'] = deviceid;
    request.fields['qrcodevalue'] = staticverible.qrval;
    request.fields['dimension'] = dimision;
    request.fields['dyeStatus'] = dyestatus;
    request.fields['nature_dye'] = naturedays;
    request.fields['weavetype'] = weavertype;
    request.fields['yarncount'] = yarncount;
    request.fields['yarntype'] = yerntype;
    request.fields['loomtype'] = loomtype;

    print(request.toString());
    if (compressedVideoPath != null) {
      var videoFile =
          await http.MultipartFile.fromPath('video', compressedVideoPath);
      request.files.add(videoFile);
    }

    if (imagePath != null) {
      var imageFile = await http.MultipartFile.fromPath('image', imagePath);
      request.files.add(imageFile);
    }

    var streamedResponse = await request.send();
    print(request.toString());
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = response.body;

      final document = xml.XmlDocument.parse(responseBody);
      final root = document.rootElement;

      if (root.name.local == 'string') {
        String message = root.text.trim();
        Map<String, dynamic> jsonResponse = json.decode(message);
        if (jsonResponse.containsKey("message")) {
          responseMessage = jsonResponse["message"];
          if (responseMessage == "Data Added Successfully") {
            showMessageDialog(context, responseMessage);
            if (imagePath != null) {
              deleteFile(imagePath);
            }
            if (compressedVideoPath != null) {
              await File(compressedVideoPath).delete();
            }
          }
        }
      } else {
        throw FormatException('Unexpected format for response');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      Navigator.of(context).pop();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Bottom_Screen()));
      throw http.ClientException(
          'Failed to load UploadFiles HTTP Status Code: ${response.statusCode}');
    }
  } catch (e) {
    List<String?> nullFieldNames = [];
    if (imagePath == null) {
      nullFieldNames.add('imagePath');
    }
    if (compressedVideoPath == null) {
      nullFieldNames.add('compressedVideoPath');
    }
    await UploadFilelogs(nullFieldNames, '$e');
    Navigator.of(context).pop();
  }
  return responseMessage;
}

Future<void> UploadFilelogs(
    List<String?>? nullFieldNames, String? message) async {
  try {
    File? errorLog = await initializeErrorlogs();
    if (errorLog != null) {
      IOSink sink = errorLog.openWrite(mode: FileMode.append);

      if (message != null) {
        if (nullFieldNames != null && nullFieldNames.isNotEmpty) {
          sink.write('Null fields: ${nullFieldNames.join(', ')}\n');
          sink.write('Message: $message\n');
          print(
              'Error logged: Null fields: ${nullFieldNames.join(', ')} - Message: $message');
        } else {
          sink.write('Null fields: None\n');
          sink.write('Message: $message\n');
          print('Error logged: Null fields: None - Message: $message');
        }
      } else {
        if (nullFieldNames != null && nullFieldNames.isNotEmpty) {
          sink.write('Null fields: ${nullFieldNames.join(', ')}\n');
          sink.write('Message: Message is null\n');
          print(
              'Error logged: Null fields: ${nullFieldNames.join(', ')} - Message: Message is null');
        } else {
          sink.write('Null fields: None\n');
          sink.write('Message: Message is null\n');
          print('Error logged: Null fields: None - Message: Message is null');
        }
      }

      // Close the file
      await sink.flush();
      await sink.close();
    } else {
      print('Error log initialization failed. Cannot log error: $message');
    }
  } catch (e) {
    print('Error logging error: $e');
  }
}

void deleteFile(String? filePath) {
  if (filePath != null) {
    try {
      File file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
        print('Deleted file: $filePath');
      }
    } catch (e) {
      print('Failed to delete file: $filePath, Error: $e');
    }
  }
}

Future<void> insertData(
  BuildContext context,
  String selectedState,
  String selectedDistrict,
  String selectedDepartment,
  String selecttype,
  String selectrole,
  TextEditingController firstcontroller,
  TextEditingController lastcontroller,
  String selectedGender,
  TextEditingController datecontroller,
  TextEditingController emailcontroller,
  TextEditingController mobilecontroller,
  TextEditingController orgnazationcontroller,
  String selectdoc,
  String selectedVillage,
  String? imageFile,
  TextEditingController weaverid,
) async {
  try {
    final String apiurl = staticverible.temqr + "/register.asmx/RegisterUser";
    var request = http.MultipartRequest('POST', Uri.parse(apiurl));

    request.fields['state'] = selectedState;
    request.fields['district'] = selectedDistrict;
    request.fields['department'] = selectedDepartment;
    request.fields['type'] = selecttype;
    request.fields['role'] = selectrole;
    request.fields['firstname'] = firstcontroller.text;
    request.fields['lastname'] = lastcontroller.text;
    request.fields['gender'] = selectedGender;
    request.fields['dob'] = datecontroller.text;
    request.fields['email'] = emailcontroller.text;
    request.fields['mobileno'] = mobilecontroller.text;
    request.fields['organization'] = orgnazationcontroller.text;
    request.fields['documentname'] = selectdoc;
    request.fields['documentno'] = imageFile ?? '';
    request.fields['city'] = selectedVillage;
    request.fields['weaverid'] = weaverid.text;
    print('Request Payload: ${request.fields}');
    final response = await request.send();
    if (response.statusCode == 200) {
      final dynamic responseData = await response.stream.bytesToString();
      print('Response Body: $responseData');

      final document = xml.XmlDocument.parse(responseData);
      var stringNode = document.findAllElements('string').first;
      var jsonString = stringNode.text;

      // Parse JSON
      Map<String, dynamic> dataMap = json.decode(jsonString);
      String message = dataMap['message'];
      if (message ==
          "User Added SuccessFully. Link to check User Status is sent to Your Registered Email ID") {
        Navigator.of(context).pop();
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: "Registered Mail",
          text: message,
          onConfirmBtnTap: () {
            Navigator.of(context).pop();
            orgnazationcontroller.clear();
            lastcontroller.clear();
            firstcontroller.clear();
            datecontroller.clear();
            emailcontroller.clear();
            mobilecontroller.clear();
            weaverid.clear();
          },
        );
      } else {
        showMessageDialog(context, message);
        Navigator.of(context).pop();
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      throw http.ClientException('Failed to load: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    logError('$e');
    Navigator.of(context).pop();
  }
}

class Temporg {
  final List<String> orgNames;

  Temporg({required this.orgNames});
}

class TempOrgAPIs {
  final String OrgApis =
      staticverible.temqr + "/organizationmaster.aspx/GetorgData";

  Future<List<String>> organizationapi(
      String state1, String district, String department, String type) async {
    try {
      final Map<String, dynamic> requestBody = {
        "state": state1,
        'district': district,
        'department': department,
        'type': type
      };

      final response = await http.post(
        Uri.parse(OrgApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);
          final List<dynamic> orgArray = dataMap['orgArray'];
          final List<String> orgNames =
              orgArray.map((org) => org as String).toList();

          return orgNames;
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load Organization HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load Organization: $e');
    }
  }
}

class TempWearver {
  final List<String> wearverNames;

  TempWearver({required this.wearverNames});
}

class TempWearverAPIs {
  final String WearverApis =
      staticverible.temqr + "/weavermaster.aspx/GetweaverData";

  Future<List<String>> Fetchwearver(BuildContext context) async {
    try {
      final Map<String, dynamic> requestBody = {
        "state": staticverible.state,
        'district': staticverible.distric,
        'department': staticverible.department,
        'type': staticverible.type,
        'organization': staticverible.organization,
        'city': staticverible.city,
        'weaverid': staticverible.weaverid
      };

      final response = await http.post(
        Uri.parse(WearverApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);
          final List<dynamic> weaverArray = dataMap['weaverArray'];
          final List<String> weaverNames =
              weaverArray.map((weaver) => weaver as String).toList();

          return weaverNames;
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load Weaver HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load Weaver: $e');
    }
  }
}

// // get organazation
class Tempgetorg {
  final List<String> orgNames;

  Tempgetorg({required this.orgNames});
}

class TempgetOrgAPIs {
  final String getOrgApis =
      staticverible.temqr + "/organizationmaster.aspx/GetorgData";

  Future<List<String>> getorganizationapi() async {
    try {
      final Map<String, dynamic> requestBody = {
        "state": staticverible.state,
        "district": staticverible.distric,
        "department": staticverible.department,
        "type": staticverible.type,
        "city": staticverible.city
      };

      final response = await http.post(
        Uri.parse(getOrgApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData != null && responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);
          final List<dynamic> orgArray = dataMap['orgArray'];
          final List<String> orgNames =
              orgArray.map((org) => org as String).toList();

          return orgNames;
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load Organization. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load Organization: $e');
    }
  }
}

// Login
class login {
  final String tempurl;
  int status;

  login({required this.tempurl, required this.status});
}

class LoginAPIs {
  final String logUrl = "${staticverible.tempip}" + '/login.aspx/CheckLogin';

  LoginAPIs() {
    print(staticverible.tempip);
    print(logUrl);
  }

  Future<Login> fetchLogin(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      final Map<String, dynamic> requestBody = {
        "username": username,
        "password": password
      };
      final response = await http.post(
        Uri.parse(logUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        final dynamic responseDataD = responseData['d'];

        if (responseDataD != null && responseDataD is String) {
          final Map<String, dynamic> dataMap = json.decode(responseDataD);
          if (dataMap['statuscode'] == "1") {
            String message = dataMap['message'].toString();
            int statusCode = int.parse(dataMap['statuscode']);
            staticverible.username = dataMap['userid'].toString();
            staticverible.state = dataMap['state'].toString();
            staticverible.distric = dataMap['district'].toString();
            staticverible.department = dataMap['department'].toString();
            staticverible.type = dataMap['type'].toString();
            staticverible.rolename = dataMap['role'].toString();
            staticverible.organization = dataMap['organization'].toString();
            staticverible.fistname = dataMap['firstname'].toString();
            staticverible.lastname = dataMap['lastname'].toString();
            staticverible.email = dataMap['email'].toString();
            staticverible.city = dataMap['city'].toString();
            staticverible.firstlogin = dataMap['first_login'].toString();
            staticverible.weaverid = dataMap['weaverid'].toString();
            staticverible.dateofbirth = dataMap['dob'].toString();
            Login newLogin = Login(
              username: username,
              password: password,
              tempmass: message,
              status: statusCode,
            );
            return newLogin;
          } else if (dataMap['statuscode'] == "0") {
            String message = dataMap['message'].toString();
            int statusCode = 0;
            staticverible.username = dataMap['userid'].toString();
            staticverible.state = dataMap['state'].toString();
            staticverible.distric = dataMap['district'].toString();
            staticverible.department = dataMap['department'].toString();
            staticverible.type = dataMap['type'].toString();
            staticverible.rolename = dataMap['role'].toString();
            staticverible.organization = dataMap['organization'].toString();
            staticverible.fistname = dataMap['firstname'].toString();
            staticverible.lastname = dataMap['lastname'].toString();
            staticverible.email = dataMap['email'].toString();
            staticverible.city = dataMap['city'].toString();
            staticverible.firstlogin = dataMap['first_login'].toString();
            Login newLogin = Login(
              username: username,
              password: password,
              tempmass: message,
              status: statusCode,
            );
            return newLogin;
          } else {
            String errorMessage = dataMap['message'].toString();
            if (errorMessage == 'Invalid UserId or Password.') {
              showMessageDialog(context, errorMessage);
            }
            print(errorMessage);
            throw Exception(errorMessage);
          }
        } else {
          throw Exception('Unexpected data format for "d"');
        }
      } else {
        print('${response.statusCode}');
        print('${response.body}');
        throw (' ${response.statusCode}');
      }
    } catch (e) {
      print('$e');
      logError('$e');
      throw ('$e');
    }
  }
}

class ResetPassAPIs {
  final String resetUrl =
      "${staticverible.tempip}" + '/firstlogin.aspx/Setpassword';

  Future<void> updatePassword(String username, String newPassword) async {
    try {
      final Map<String, dynamic> requestBody = {
        "username": username,
        "password": newPassword
      };
      final response = await http.post(
        Uri.parse(resetUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        final dynamic responseDataD = responseData['d'];

        if (responseDataD != null && responseDataD is String) {
          final Map<String, dynamic> dataMap = json.decode(responseDataD);
          if (dataMap['message'] ==
              "Password successfully changed. You can now access your account.") {
          } else {
            String errorMessage = dataMap['message'].toString();
            print(errorMessage);
            throw Exception(errorMessage);
          }
        }
      } else {
        print('Failed to Reset password: ${response.statusCode}');
        print('${response.body}');
        throw Exception('Failed to Reset password: ${response.statusCode}');
      }
    } catch (e) {
      print('Error Reset password: $e');
      logError('$e');
      throw Exception('Error Reset password: $e');
    }
  }
}

// get product
class tempProduct {
  final List<String> productName;

  tempProduct({required this.productName});
}

class Tempgetproduct {
  final String getproductApis =
      staticverible.temqr + "/productmaster.aspx/getproductdata";

  Future<List<String>> getproductapi(BuildContext context) async {
    try {
      final Map<String, dynamic> requestBody = {
        "state": staticverible.state,
        "productname": "",
      };

      final response = await http.post(
        Uri.parse(getproductApis),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData != null && responseData['d'] is String) {
          final Map<String, dynamic> dataMap = json.decode(responseData['d']);
          final List<dynamic> productArray = dataMap['prdArray'];
          final List<String> productnames =
              productArray.map((product) => product as String).toList();

          return productnames;
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw http.ClientException(
            'Failed to load product. HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load product: $e');
    }
  }
}

// Upload service start
Future<void> uploadservicedata({
  required BuildContext context,
  required String qrcodevalue,
  required DateTime startdate,
  required double latitude,
  required double longitude,
}) async {
  try {
    final String devicesohApis =
        staticverible.temqr + '/UploadService.asmx/ADDData';

    var request = http.MultipartRequest('POST', Uri.parse(devicesohApis));

    request.fields['qrcodevalue'] = staticverible.qrval;
    request.fields['startdate'] = startdate.toString();
    request.fields['state'] = staticverible.state;
    request.fields['district'] = staticverible.distric;
    request.fields['department'] = staticverible.department;
    request.fields['city'] = staticverible.city;
    request.fields['type'] = staticverible.type;
    request.fields['organization'] = staticverible.organization;
    request.fields['createdby'] = staticverible.username;
    request.fields['longitude'] = longitude.toString();
    request.fields['latitude'] = latitude.toString();

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final document = xml.XmlDocument.parse(responseBody);
      final root = document.rootElement;

      if (root.name.local == 'string') {
        String message = root.text.trim();
        Map<String, dynamic> jsonResponse = json.decode(message);
        if (jsonResponse.containsKey("message")) {
          String responseMessage = jsonResponse["message"];
          if (responseMessage == "Data Added Successfully") {
            showMessageDialog(context, responseMessage);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => AddProduct_Screen(
                          qrVal: staticverible.qrval,
                          startDate: startdate,
                          qrtext: staticverible.qrval,
                        )));
          } else {
            showRegisteredMessage(context, responseMessage);
            Navigator.of(context).pop();
          }
        }
      } else {
        throw FormatException('Unexpected format for response');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      throw http.ClientException(
          'Failed to load Upload data Start File HTTP Status Code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    logError('$e');
  }
}

//  product end api
Future<void> uploadserviceenddata(
    {required BuildContext context,
    required String qrcodevalue,
    required DateTime enddate}) async {
  try {
    plaesewaitmassage(context);
    final String devicesohApis =
        staticverible.temqr + '/UploadService.asmx/Updateprdenddate';

    var request = http.MultipartRequest('POST', Uri.parse(devicesohApis));

    request.fields['qrcodevalue'] = qrcodevalue;
    request.fields['enddate'] = enddate.toString();
    request.fields['status'] = 'End';

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final document = xml.XmlDocument.parse(responseBody);
      final root = document.rootElement;

      if (root.name.local == 'string') {
        String message = root.text.trim();
        Map<String, dynamic> jsonResponse = json.decode(message);
        if (jsonResponse.containsKey("message")) {
          String responseMessage = jsonResponse["message"];
          if (responseMessage == "Data Added Successfully") {
            showMessageDialog(context, responseMessage);
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => Productlist_Screen(),
              ),
            );
          } else {
            showRegisteredMessage(context, responseMessage);
            Navigator.of(context).pop();
          }
        }
      } else {
        throw FormatException('Unexpected format for response');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      Navigator.of(context).pop();
      throw http.ClientException(
          'Failed to load Upload end data File  HTTP Status Code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    logError('$e');
    Navigator.of(context).pop();
  }
}

class Getprodata {
  final List<String> dymesion;

  Getprodata({required this.dymesion});
}

class DymesionApis {
  final String dymesionaurl =
      staticverible.temqr + "/productspecificationmaster.aspx/GetprdData";

  Future<List<Map<String, String>>> dymesionproduct(
      String productname, BuildContext context) async {
    try {
      final Map<String, dynamic> requestBody = {
        "state": staticverible.state,
        'productname': productname,
      };
      final response = await http.post(
        Uri.parse(dymesionaurl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData['d'] is String) {
          final List<dynamic> decodedList = json.decode(responseData['d']);
          final List<Map<String, String>> innerDataList =
              decodedList.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'type': item['type'] as String,
                'value': item['value'] as String,
              };
            } else {
              throw FormatException(
                  'Unexpected data format for item in response');
            }
          }).toList();

          return innerDataList;
        } else {
          throw FormatException('Unexpected data format for "d"');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        throw http.ClientException(
            'Failed to load Weaver HTTP Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      logError('$e');
      throw Exception('Failed to load get product data: $e');
    }
  }
}

class ProductView {
  String status;
  String state;
  String district;
  String department;
  String type;
  String organazation;
  String city;
  String createdBy;
  String qrcodeval;
  String image;
  String video;
  String wearverName;
  String deviceid;
  String qrtextfinal;
  String qrimage;
  String productname;

  ProductView(
      {required this.status,
      required this.state,
      required this.district,
      required this.department,
      required this.type,
      required this.organazation,
      required this.city,
      required this.createdBy,
      required this.qrcodeval,
      required this.image,
      required this.video,
      required this.wearverName,
      required this.deviceid,
      required this.qrtextfinal,
      required this.qrimage,
      required this.productname});
}

List<ProductView> parseXmlResponse(xml.XmlDocument responseData) {
  List<ProductView> productviewStatus = [];
  final jsonString = responseData.rootElement.text;

  dynamic jsonData = json.decode(jsonString);

  if (jsonData is List) {
    for (final item in jsonData) {
      final productview = ProductView(
        status: item['status'] ?? "",
        state: item['state'] ?? "",
        district: item['district'] ?? "",
        department: item['department'] ?? "",
        type: item['type'] ?? "",
        organazation: item['organization'] ?? "",
        city: item['city'] ?? "",
        createdBy: item['createdby'] ?? "",
        qrcodeval: item['qrcodevalue'] ?? "",
        image: item['image'] ?? "",
        video: item['video'] ?? "",
        wearverName: item['weavername'] ?? "",
        deviceid: item['devicecode'] ?? "",
        qrtextfinal: item['qrtextfinal'] ?? "",
        qrimage: item['qrimage'] ?? "",
        productname: item['productname'] ?? "",
      );
      productviewStatus.add(productview);
    }
  } else if (jsonData is Map) {
    final productview = ProductView(
      status: jsonData['status'] ?? "",
      state: jsonData['state'] ?? "",
      district: jsonData['district'] ?? "",
      department: jsonData['department'] ?? "",
      type: jsonData['type'] ?? "",
      organazation: jsonData['organization'] ?? "",
      city: jsonData['city'] ?? "",
      createdBy: jsonData['createdby'] ?? "",
      qrcodeval: jsonData['qrcodevalue'] ?? "",
      image: jsonData['image'] ?? "",
      video: jsonData['video'] ?? "",
      wearverName: jsonData['weavername'] ?? "",
      deviceid: jsonData['devicecode'] ?? "",
      qrtextfinal: jsonData['qrtextfinal'] ?? "",
      qrimage: jsonData['qrimage'] ?? "",
      productname: jsonData['productname'] ?? "",
    );
    productviewStatus.add(productview);
  } else {
    print("Unknown data format");
  }

  return productviewStatus;
}

void launchImageURL(String imageUrl) async {
  String url = staticverible.temqr + '/' + imageUrl;

  try {
    await launch(url);
  } catch (e) {
    throw 'Could not launch $url: $e';
  }
}

void launchvideosURL(String videosUrl) async {
  String url = staticverible.temqr + '/' + videosUrl;
  try {
    await launch(url);
  } catch (e) {
    throw 'Could not launch $url: $e';
  }
}

Future<List<ProductView>> GetProductwiseData(
    BuildContext context, DateTime fromDt, DateTime toDt) async {
  final String apiUrl =
      staticverible.temqr + "/UploadService.asmx/GetprdDatauserwise";

  if (fromDt.isBefore(DateTime(1753, 1, 1)) ||
      toDt.isAfter(DateTime(9999, 12, 31))) {
    throw Exception('Date range is out of valid SQL DateTime range.');
  }

  // Format the dates
  DateFormat dateFormat = DateFormat('dd-MM-yyyy');
  String formattedFromDate = dateFormat.format(fromDt);
  String formattedToDate = dateFormat.format(toDt);

  final Map<String, String> queryParams = {
    'state': staticverible.state,
    'district': staticverible.distric,
    'department': staticverible.department,
    'city': staticverible.city,
    'type': staticverible.type,
    'organization': staticverible.organization,
    'createdby': staticverible.username,
    'fromdate': formattedFromDate.toString(),
    'todate': formattedToDate.toString()
  };

  final Uri uri = Uri.parse(apiUrl);

  try {
    http.Response response = await http.post(uri, body: queryParams);

    if (response.statusCode == 200) {
      xml.XmlDocument responseData = xml.XmlDocument.parse(response.body);
      List<ProductView> parsedData = parseXmlResponse(responseData);

      return parsedData;
    } else {
      print("Request failed with status: ${response.statusCode}");
      print("Request failed with status: ${response.body}");
      logError('${response.statusCode}' + '' + '${response.body}');
      Navigator.of(context).pop();
      return [];
    }
  } catch (e) {
    print('Error occurred: $e');
    logError('$e');
    Navigator.of(context).pop();
    return [];
  }
}
