# react-native-video-manager

[![npm](https://img.shields.io/npm/v/react-native-video-manager)](https://www.npmjs.com/package/react-native-video-manager) ![Supports Android, iOS](https://img.shields.io/badge/platforms-android%20%7C%20ios-lightgrey.svg) ![MIT License](https://img.shields.io/npm/l/react-native-safe-area-context.svg)

Module cross platform to merge multiple videos.

This tool based on [`react-native-video-editor`](https://www.npmjs.com/package/react-native-video-editor), with working example, support to newer React Native versions, and more improvements.

## Installation

```sh
yarn add react-native-video-manager
```

or

```sh
npm install react-native-video-manager
```

You then need to link the native parts of the library for the platforms you are using.

- **iOS Platform:**

`$ npx pod-install`

- **Android Platform:**

`no additional steps required`

## Usage

```js
import { VideoManager } from "react-native-video-manager";

// ...
const videos = ["file:///video1.mp4", "file:///video2.mp4"];

try {
  const { uri } = await VideoManager.merge(videos);

  console.log("merged video path", uri);
} catch (error) {
  console.log(error);
}
// ...
```

You can also check a complete example in `/example` folder.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
