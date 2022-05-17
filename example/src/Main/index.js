import React, { useState, useEffect, useRef } from "react";
import {
  Text,
  View,
  TouchableOpacity,
  Image,
  FlatList,
  ActivityIndicator,
} from "react-native";
import { Camera } from "expo-camera";
import { MaterialIcons } from "@expo/vector-icons";
import * as VideoThumbnails from "expo-video-thumbnails";
import { VideoManager } from "react-native-video-manager";

import { styles } from "./styles";

import PLayModal from "./components/PlayModal";

export default function Main() {
  const [hasPermission, setHasPermission] = useState(null);
  const [type, setType] = useState(Camera.Constants.Type.front);
  const [isRecording, setIsRecording] = useState(false);
  const [isMerging, setIsMerging] = useState(false);
  const [isOpenModal, setIsOpenModal] = useState(false);
  const [videoUri, setVideoUri] = useState("");
  const [videos, setVideos] = useState([]);
  const [thumbs, setThumbs] = useState([]);

  const cameraRef = useRef(null);

  useEffect(() => {
    (async () => {
      const { status } = await Camera.requestCameraPermissionsAsync();
      const { status: MicStatus } = await Camera.requestMicrophonePermissionsAsync();
      const allowed = status === "granted" && MicStatus === "granted";

      setHasPermission(allowed);
    })();
  }, []);

  function handleFlip() {
    setType(
      type === Camera.Constants.Type.back
        ? Camera.Constants.Type.front
        : Camera.Constants.Type.back
    );
  }

  async function handleRecord() {
    if (isRecording) {
      cameraRef.current.stopRecording();
      setIsRecording(false);
    } else {
      setIsRecording(true);
      const { uri } = await cameraRef.current.recordAsync({ maxDuration: 5 });
      const { uri: thumbUri } = await VideoThumbnails.getThumbnailAsync(uri);

      setThumbs((prev) => [...prev, thumbUri]);
      setVideos((current) => [...current, uri]);
      setIsRecording(false);
    }
  }

  async function handleMerge() {
    if (videos.length < 2) return;

    setIsMerging(true);

    try {
      const { uri } = await VideoManager.merge(videos);

      setIsMerging(false);
      setVideoUri(uri);
      setIsOpenModal(true);
    } catch (error) {
      setIsMerging(false);
      console.log(error);
    }
  }

  if (hasPermission === null) {
    return <View />;
  }

  if (hasPermission === false) {
    return <Text>No access to camera</Text>;
  }

  return (
    <View style={styles.container}>
      <View style={styles.camerContent}>
        <Camera ref={cameraRef} style={styles.camera} type={type}>
          <View style={styles.buttonContainer}>
            <TouchableOpacity style={styles.flipButton} onPress={handleFlip}>
              <MaterialIcons name="flip-camera-android" size={24} color="white" />
            </TouchableOpacity>
            <TouchableOpacity
              onPress={handleRecord}
              style={[
                styles.recButton,
                { backgroundColor: isRecording ? "green" : "red" },
              ]}
            />
          </View>
        </Camera>
      </View>
      <FlatList
        data={thumbs}
        keyExtractor={(item) => item}
        horizontal
        contentContainerStyle={{ alignItems: "center" }}
        renderItem={({ item }) => (
          <Image source={{ uri: item }} resizeMode="contain" style={styles.thumb} />
        )}
      />
      <TouchableOpacity onPress={handleMerge} style={styles.mergeButton}>
        <Text style={styles.mergeButtonText}>
          {isMerging ? <ActivityIndicator color="white" /> : "MERGE VIDEOS"}
        </Text>
      </TouchableOpacity>
      <PLayModal
        videoUri={videoUri}
        isOpen={isOpenModal}
        close={() => setIsOpenModal(false)}
      />
    </View>
  );
}
