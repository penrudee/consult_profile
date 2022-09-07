import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:learn_layout/locator.dart';

import 'package:learn_layout/services/database_service.dart';
import '../profile/avatar.dart';

import 'package:learn_layout/utility/my_constant.dart';
import 'package:learn_layout/view_controller/user_controller.dart';

import '../models/user_models.dart';
import '../services/cloud_storage_service.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  UserModel _currentUser = locator.get<UserController>().currentUser;

  DatabaseService? _db;
  bool statusRedEye = true;
  bool statusRedEyeConfirmPassWord = true;
  bool checkCurrentPasswordValid = true;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  CloudStorageService? _cloudStorage; //1.0.0

  @override
  void initState() {
    super.initState();
    displayNameController =
        TextEditingController(text: _currentUser.displayName);

    getavatarUrlFromFirebaseStoreage();
  }

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
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
                    var userController = locator.get<UserController>();
                    if (_currentUser.displayName !=
                        displayNameController.text) {
                      var displayname = displayNameController.text;
                      userController.updateDisplayName(displayname);
                    }
                  },
                  child: Text(
                    'Update Profile!',
                    style: TextStyle(color: MyConstant.light),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  _picImageFromGallery() async {
    PickedFile? pickedFile =
        await ImagePicker.platform.pickImage(source: ImageSource.gallery);

    var imagePath = pickedFile!.path;

    File? imageFile = File(imagePath);
    print("image File from profile.dart line 153 = $imageFile");
    print("current user uid from profile.dart line 152 = ${_currentUser.uid}");
    String? _imageURL = await _cloudStorage?.saveUserImageToStorage_FileType(
        _currentUser.uid, imageFile);
    print("image url from profile.dart line 157 = $_imageURL");
    await _db?.editUser(
        uid: _currentUser.uid,
        email: _currentUser.email,
        displayName: displayNameController.text,
        avatarUrl: _imageURL);
    setState(() {});
    getavatarUrlFromFirebaseStoreage();
  }

  _pickImageFromCamera() async {
    PickedFile? pickedFile =
        // PlatformFile pickedFile=
        await ImagePicker.platform.pickImage(source: ImageSource.camera);
    var imagePath = pickedFile!.path;
    File imageFile = File(imagePath);

    String? _imageURL = await _cloudStorage?.saveUserImageToStorage_FileType(
        _currentUser.uid!, imageFile);
    await _db?.editUser(
        uid: _currentUser.uid,
        email: _currentUser.email,
        displayName: displayNameController.text,
        avatarUrl: _imageURL);
    setState(() {});
    getavatarUrlFromFirebaseStoreage();
  }

  String pickLinkAvatar = '';
  void getavatarUrlFromFirebaseStoreage() async {
    FirebaseStorage st = FirebaseStorage.instance;
    Reference ref = st.ref().child("user/profile/${_currentUser.uid}");
    ref.getDownloadURL().then((value) async {
      setState(() {
        pickLinkAvatar = value;
      });
    });
  }
}
