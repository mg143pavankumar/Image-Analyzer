import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_to_text/constants/constants.dart';
import 'package:image_to_text/views/onboarding.dart';

enum AppState {
  free,
  picked,
  cropped,
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppState state;
  File _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        setState(() {
          state = AppState.picked;
        });
      } else {
        print('No image selected.');
      }
    });
  }

  TextEditingController script = TextEditingController();

  Future readText(File image) async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(image);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    script.clear();
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            script.text = script.text + " " + word.text;
          });
        }
        script.text = script.text + '\n';
      }
    }
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => OnBoarding(),
      ),
    ).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueColor,
        onPressed: () {
          if (state == AppState.free) {
            getImage();
          } else if (state == AppState.picked)
            cropImage();
          else if (state == AppState.cropped) getText();
        },
        child: buildButtonIcon(),
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              Text(
                "Image Analyzer",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueColor,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      _image == null
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.blueColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    'No image selected.',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          AppColors.blueColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 300,
                              width: 300,
                              child: Image.file(_image)),
                      SizedBox(height: 20),
                      script.text == ''
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.blueColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    "No Text found. It is an object.",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          AppColors.blueColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: TextFormField(
                                controller: script,
                                minLines: 5,
                                maxLines: 100,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                                onChanged: (val) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  focusColor: AppColors.blueColor,
                                  fillColor: AppColors.blueColor,
                                  filled: true,
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.white60,
                                      width: 4.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButtonIcon() {
    if (state == AppState.free)
      return Icon(
        Icons.add,
        color: Colors.white,
      );
    else if (state == AppState.picked)
      return Icon(
        Icons.crop,
        color: Colors.white,
      );
    else if (state == AppState.cropped)
      return Icon(
        Icons.arrow_right,
        color: Colors.white,
      );
    else
      return Container();
  }

  Future<Null> cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: _image.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Crop the Image',
            toolbarColor: Color(0xff375079),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      _image = croppedFile;
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  void getText() async {
    await readText(_image);
    setState(() {
      state = AppState.free;
    });
  }
}
