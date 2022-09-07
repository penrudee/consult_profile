import 'dart:io';
// import 'package:learn_layout/repository/auth_repo.dart';
import 'package:learn_layout/utility/my_constant.dart';
import '../models/user_models.dart';
//Packages
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// import '../locator.dart';
// import '../view_controller/user_controller.dart';

const String USER_COLLECTION = "Users";

class CloudStorageService {
  final FirebaseStorage _sTorage =
      FirebaseStorage.instanceFor(bucket: MyConstant.storageBucket);

  // AuthRepo _authRepo = locator.get<AuthRepo>();
  CloudStorageService();
  // late UserModel _currentUser = locator.get<UserController>().currentUser;

  getavatarUrlFromFirebaseStoreage(String? _uid) async {
    try {
      String pickLinkAvatar = '';
      FirebaseStorage st = _sTorage;
      Reference ref = st.ref().child("user/profile/$_uid");
      print("////////////////////base uri $ref");
      ref.getDownloadURL().then((value) async {
        pickLinkAvatar = value;
        return pickLinkAvatar;
      });
    } catch (e) {
      print("Error from getImageAvartar url(cloud_storage_service.dart) $e");
    }
  }

  Future<String?> saveUserImageToStorage(
      String? _uid, PlatformFile? _file) async {
    try {
      // String TestUrl;

      Reference _ref = _sTorage.ref().child('user/profile/$_uid');
      UploadTask _task = _ref.putFile(
        File(_file?.path ?? MyConstant.blankUserProfileImage),
      );
      // _task.whenComplete(() async {
      //   String uriImage = await _ref.getDownloadURL();
      // });
      var downloadUrl = await _task.then(
        (_result) => _result.ref.getDownloadURL(),
      );

      String url = downloadUrl.toString();

      print("****download url = $url*****");

      return url;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<String?> saveUserImageToStorage_FileType(
      String? _uid, File _file) async {
    try {
      // String TestUrl;
      print("user current uid from cloud_storage_service.dart $_uid");
      Reference _ref = _sTorage.ref().child('user/profile/$_uid');

      UploadTask _task = _ref.putFile(
        _file,
      );
      // _task.whenComplete(() async {
      //   String uriImage = await _ref.getDownloadURL();
      // });
      var downloadUrl = await _task.then(
        (_result) => _result.ref.getDownloadURL(),
      );

      String url = downloadUrl.toString();

      print("****download url = $url*****");

      return url;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<String?> saveChatImageToStorage(
      String _chatID, String _userID, PlatformFile _file) async {
    try {
      Reference _ref = _sTorage.ref().child(
          'images/chats/$_chatID/${_userID}_${DateTime.now().millisecondsSinceEpoch}.${_file.extension}');
      UploadTask _task = _ref.putFile(
        File(_file.path ?? ''),
      );
      return await _task.then(
        (_result) => _result.ref.getDownloadURL(),
      );
    } catch (e) {
      print(e);
    }
    return null;
  }
}
