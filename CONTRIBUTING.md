# Contributing

## Development workflow

### Install dependencies

Use yarn to install development dependencies.

```sh
yarn
```

If you don't have expo-cli installed:

```sh
npm install -g expo-cli
```

Move to the `example` directory and install dependencies there too.

```sh
cd example
yarn
```

```sh
cd ios && pod install && cd ..
```

### Example app

Start the example app to test your changes. You can use one of the following commands from the example root, depending on the platform you want to use.

From the `example` directory:

#### iOS

```sh
yarn ios
```

for running in device

```sh
yarn device
```

I also recommend opening `example/ios/exmaple.xcworkspace` in Xcode if you need to make changes to native code.

#### Android

```sh
yarn android
```

I also recommend opening `example/android` in Android Studio if you need to make changes to native code.

### Open a pull request!
