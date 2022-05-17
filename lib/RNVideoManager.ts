import { NativeModules } from "react-native";

const { RNVideoManager } = NativeModules;

interface Response {
  uri: string;
}

export async function merge(videos: string[]): Promise<Response> {
  const uri: string = await RNVideoManager.merge(videos);

  return { uri };
}
