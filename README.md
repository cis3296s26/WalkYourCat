# WalkYourCat

[![Android Build](https://github.com/cis3296s26/WalkYourCat/actions/workflows/build-android.yaml/badge.svg)](https://github.com/cis3296s26/WalkYourCat/actions)
[![Deploy Status](https://github.com/cis3296s26/WalkYourCat/actions/workflows/deploy.yaml/badge.svg)](https://github.com/cis3296s26/WalkYourCat/actions)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white) ![Web](https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)


#### [Explore Docs](https://github.com/cis3296s26/WalkYourCat) / [Report Bug](https://github.com/cis3296s26/WalkYourCat/issues) / [Request Feature](https://github.com/cis3296s26/WalkYourCat/issues) 

---

WalkYourCat is for people who want motivation to increase their daily physical activity and exercise. It is a fitness app grounded in game theory that allows users to convert their physical activity into a positive response loop by taking care of their virtual pet.

![This is a screenshot.](week4picture.png)

## UML Class Diagram

![Class Diagram](UMLclassDiagram.png)

## Getting Started

To run and build WalkYourCat, install the flutter SDK. Flutter has [helpful instructions](https://docs.flutter.dev/install) for installation.

For help getting started with Flutter development in general, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to Run
- If it's your first time running do the following 

```
flutter doctor -v
```

### fix errors first before continuing:
```
flutter clean
flutter pub get
```
- If the above steps have been done before just skip to the next command
- Download the latest binary from the Release section on the right on GitHub.  
- On the command line do:
```
flutter run
```
- This command first checks for devices available to run the app on.

for example
```
[1]: macOS (macos)
[2]: Windows (windows)
[3]: Chrome (chrome)
```

or a connected device such as an Android or iOS phone.

- Select your chosen device/emulator to run the app.
- You will see the app open up on the browser or the phone.

## How to Contribute
Follow this project board to know the latest status of the project: [https://github.com/orgs/cis3296s26/projects/35]([https://github.com/orgs/cis3296s26/projects/35])  

## How to build locally during Development
- Clone and use this github repository: https://github.com/cis3296s26/WalkYourCat
- Specify what branch to use for a more stable release.  
- Use Andriod Studio for Android, XCode for IOS or any other IDE such as VSCode for the browser version.
- To be able to run the code dart: ">=3.9.0-0 <4.0.0" and flutter: ">=3.35.0" is required to be installed prior.
- Go to "How to run" to see how to run the app.

### Firebase Integrations
In order to use the realtime database aspect of this app you will need to use Firebase. There is a very nice guide by [Google](https://firebase.google.com/docs/database/flutter/start) that we recommend.

Once a project is created you will add a `config.json` at the root of your project like:

```json
{
    "FIREBASE_API_KEY": "xxx", 
    "FIREBASE_APP_ID": "xxx", 
    "FIREBASE_SENDER_ID": "xxx", 
    "FIREBASE_PROJECT_ID": "xxx",
    "FIREBASE_DB_URL": "xxx"
}
```

Running the project with the extra flag `--dart-define-from-file=config.json` to ensure that it is loaded into the enviroment!

## How to Build
### Android
From the Command line directly to your device:
- Connect your Android-powered device to your computer with a USB cable.
- Enable Developer Options in your Android device settings. To do this, go to `Settings > About phone > Build number`. Tap Build number 7 times and enter your device PIN for security purposes.
- When Developer Options are activated, toggle to turn on **USB Debugging**.
- On your computer terminal, enter ```cd WalkYourCat``` if not already in the project directory.
- Run  ```flutter install```.
- You will be prompted to select the device you wish to install to, something like the following:
```
[1]: macOS (macos)
[2]: Windows (windows)
[3]: Chrome (chrome)
[4]: android-xyz (android)
```
select android as it is your targeted device.

Alternatively, an apk can be built for each target Android API level:
```
    cd WalkYourCat
    flutter build apk --split-per-abi
```
### iOS (on macOS only)
Since iOS has higher security restrictions, **XCode** will be required to install on iOS.

Open WalkYourCat in XCode and run ```flutter install```. Follow the prompt to install to your device or emulator as instructed above in the **Android** section.

Alternatively, an `ipa` can be built for iOS with the following command:
- ```flutter build ipa```
### Web
- ```flutter build web```
### Desktop
- Builds a native Windows executable (.exe) and necessary DLL files

    - ```flutter build windows ```

- Builds a native macOS executable for Intel or Apple Silicon architecture

    - ```flutter build macos ```

- Builds a native Linux executable

    - ```flutter build linux```


## How to install
### Android
- Follow instructions given in Build to enable developer mode on your device.
- Download the ```.apk``` file from the latest [release](https://github.com/cis3296s26/WalkYourCat/releases) to your device.
- After downloading the file to your Android device, run the ```.apk``` and give it the permission to install WalkYourCat.


Note: If using an Android emulator, the ```.apk``` file can be dragged and dropped from the file explorer of your operating system to anywhere on the emulator screen. Alternatively, one can run ```adb install path\to\apk``` to transfer the file to the emulator. Subsequently, the above step can be performed to install the app using the ```.apk```.

### iOS (on macOS only)
Refer to Build instructions for installation process.