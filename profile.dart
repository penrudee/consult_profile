import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:learn_layout/locator.dart';
// import 'package:learn_layout/repository/auth_repo.dart';

// import 'package:learn_layout/services/database_service.dart';
import 'package:learn_layout/widgets/snacbar_error.dart';
import '../profile/avatar.dart';

import 'package:learn_layout/utility/my_constant.dart';
import 'package:learn_layout/view_controller/user_controller.dart';

import '../models/user_models.dart';
// import '../services/cloud_storage_service.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  UserModel _currentUser = locator.get<UserController>().currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _sTorage =
      FirebaseStorage.instanceFor(bucket: MyConstant.storageBucket);

  // DatabaseService? _db;
  bool statusRedEye = true;
  bool statusRedEyeConfirmPassWord = true;
  bool checkCurrentPasswordValid = true;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  // CloudStorageService? _cloudStorage; //1.0.0

  @override
  void initState() {
    super.initState();

    displayNameController =
        TextEditingController(text: _auth.currentUser?.displayName);

    getavatarUrlFromFirebaseStoreage();
  }

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
    String displayName2;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Profile",
          style: TextStyle(fontFamily: "Kanit Regular"),
        ),
        backgroundColor: MyConstant.primary,
      ),
      body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          behavior: HitTestBehavior.opaque,
          child: ListView(
            padding: EdgeInsets.all(size * 0.03),
            children: <Widget>[
              Avatar(
                  currentUser: _currentUser,
                  avatarUrl: _currentUser.avatarUrl ?? pickLinkAvatar,
                  onTap: () async {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.image),
                                  title: const Text("From Gallery"),
                                  onTap: () {
                                    _picImageFromGallery();

                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("From Camera"),
                                  onTap: () {
                                    _pickImageFromCamera();

                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                )
                              ],
                            ),
                          );
                        });
                  }),
              SizedBox(height: 20.0),
              TextFormField(
                  controller: displayNameController,
                  decoration: InputDecoration(
                    labelStyle: MyConstant().h3Style(),
                    labelText: 'User name:',
                    prefixIcon: Icon(
                      Icons.account_box_outlined,
                      color: MyConstant.dark,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyConstant.dark),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyConstant.light),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  )),
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                width: size * 0.8,
                child: ElevatedButton(
                  style: MyConstant().myButtonStyle(),
                  onPressed: () async {
                    // var userController = locator.get<UserController>();
                    if (_currentUser.displayName !=
                        displayNameController.text) {
                      displayName2 = displayNameController.text;
                      await EditDisplayName(displayName2);
                      Navigator.pop(context);
                    } else {
                      showWarningSnacbar(context, "Profile is updated");
                    }
                  },
                  child: Text(
                    "Update User Profile",
                    style: MyConstant().h3White(),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  _picImageFromGallery() async {
    final firebaseUser = _auth.currentUser;
    final uid = firebaseUser?.uid;
    final email = firebaseUser?.email;
    final displayName = firebaseUser?.displayName;
    final avatarUrl = firebaseUser?.photoURL;
    print("user uid = $uid");
    print("user email = $email");
    print("user displayname = $displayName");
    print("user avatarUrl = $avatarUrl");
    print("**************************");
    print("current user imageUrl = ${_auth.currentUser?.photoURL}");
    PickedFile? pickedFile =
        await ImagePicker.platform.pickImage(source: ImageSource.gallery);

    var imagePath = pickedFile?.path;

    File? imageFile = File(imagePath ?? MyConstant.backbutton);

    print("imageFile =$imageFile");

    String? _imageUrl = await saveAvatarUrlToStorage(uid, imageFile);

    await EditProfileInFirebaseForeStore(
      uid,
      email,
      displayName,
      _imageUrl,
    );

    setState(() {});
    getavatarUrlFromFirebaseStoreage();
  }

  EditProfileInFirebaseForeStore(
      String? uid, String? email, String? displayName, String? imageUrl) async {
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "email": email,
      "displayName": displayName,
      "avatarUrl": imageUrl,
      "last_active": DateTime.now().toUtc(),
    });
    await _auth.currentUser?.updatePhotoURL(imageUrl);

    print("save new profile");
  }

  EditDisplayName(
    String? displayName,
  ) async {
    final firebaseUser = _auth.currentUser;
    final uid = firebaseUser?.uid;
    final email = firebaseUser?.email;

    final avatarUrl = firebaseUser?.photoURL;
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      // "email": email,
      "displayName": displayName,
      // "avatarUrl": avatarUrl,
      "last_active": DateTime.now().toUtc(),
    });
    await _auth.currentUser?.updateDisplayName(displayName);
    print("save new displayname");
  }

  _pickImageFromCamera() async {
    final firebaseUser = _auth.currentUser;
    final uid = firebaseUser?.uid;
    final email = firebaseUser?.email;
    final displayName = firebaseUser?.displayName;
    final avatarUrl = firebaseUser?.photoURL;
    PickedFile? pickedFile =
        // PlatformFile pickedFile=
        await ImagePicker.platform.pickImage(source: ImageSource.camera);
    var imagePath = pickedFile?.path;
    File imageFile = File(imagePath ?? MyConstant.bakamol);

    String? _imageURL = await saveAvatarUrlToStorage(uid!, imageFile);

    await EditProfileInFirebaseForeStore(uid, email, displayName, _imageURL);
    setState(() {});
    getavatarUrlFromFirebaseStoreage();
  }

  String pickLinkAvatar = '';
  void getavatarUrlFromFirebaseStoreage() async {
    FirebaseStorage st = FirebaseStorage.instance;
    Reference ref = st.ref().child("user/profile/${_auth.currentUser?.uid}");
    ref.getDownloadURL().then((value) async {
      setState(() {
        pickLinkAvatar = value;
      });
    });
  }

  Future<String?> saveAvatarUrlToStorage(String? _uid, File _file) async {
    try {
      Reference _ref = _sTorage.ref().child('user/profile/$_uid');
      await _ref.delete();
      UploadTask _task = _ref.putFile(
        _file,
      );
      var downloadUrl = await _task.then(
        (_result) => _result.ref.getDownloadURL(),
      );

      String url = downloadUrl.toString();

      print("****download url = $url*****");

      return url;
    } catch (e) {
      print("Error from upload/download image = $e");
    }
  }

  void gallaryImage() async {
    File? imagePicked;
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    final pickedImageFile = File(pickedImage!.path);
    setState(() {
      imagePicked = pickedImageFile;
    });
  }
}
