import 'package:get/get.dart';

class LocaleString extends Translations {
  @override
  // TODO: implement keys
  Map<String, Map<String, String>> get keys => {
        //ENGLISH LANGUAGE
        'en_US': {
          'hello': 'Add Product',
          'message': 'Image',
          'title': 'Videos',
          'sub': 'Location',
          'changelang': 'Device',
          'Apis': 'APIs',
        },
        //HINDI LANGUAGE
        'hi_IN': {
          'hello': 'क्यूआर स्कैन',
          'message': 'इमेजिस',
          'title': 'वीडियो',
          'sub': 'जगह',
          'changelang': 'ब्लूटूथ',
          'Apis': 'एपिस',
        },
        // ASSAMESE LANGUAGE
        'as_IN': {
          'hello': 'QR স্কেন',
          'message': 'ছৱি',
          'title': 'ভিডিঅ',
          'sub': 'অৱস্থান',
          'changelang': 'ব্লুটুথ',
          'Apis': 'আপিছ',
        }
      };
}
