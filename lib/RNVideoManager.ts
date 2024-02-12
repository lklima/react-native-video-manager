import { NativeModules } from "react-native";
const { RNVideoManager } = NativeModules;
interface Response {
  uri: string;
}

export async function merge(videos: string[]): Promise<Response> {
  const uri: string = await RNVideoManager.merge(videos);

  return { uri };
}

export async function trim(video: string, start: number, end: number): Promise<Response> {
  const uri: string = await RNVideoManager.trim(video, start, end);

  return { uri };
}

export async function getVideoDuration(path: string): Promise<number> {
  const videoDuration = await RNVideoManager.getVideoDuration(path);
  return videoDuration;
}