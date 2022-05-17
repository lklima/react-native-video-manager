import React from "react";
import { Text, View, TouchableOpacity, Modal } from "react-native";
import { Video } from "expo-av";

import { styles } from "./styles";

export default function PLayModal({ videoUri, isOpen, close }) {
  return (
    <Modal visible={isOpen} transparent>
      <View style={styles.backdrop}>
        <View style={styles.container}>
          <Video
            style={styles.video}
            source={{
              uri: videoUri,
            }}
            useNativeControls
            resizeMode="contain"
          />
          <TouchableOpacity onPress={close} style={styles.button}>
            <Text>CLOSE</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}
