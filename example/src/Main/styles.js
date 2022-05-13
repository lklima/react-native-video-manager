import { StyleSheet } from "react-native";

export const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camerContent: {
    height: "70%",
  },
  camera: {
    flex: 1,
  },
  buttonContainer: {
    flexDirection: "row",
    position: "absolute",
    bottom: 0,
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
  },
  flipButton: {
    position: "absolute",
    left: 20,
    height: 40,
    width: 40,
    borderRadius: 40,
    backgroundColor: "rgba(0, 0, 0, 0.4)",
    alignItems: "center",
    justifyContent: "center",
  },
  recButton: {
    height: 60,
    width: 60,
    borderRadius: 30,
    borderWidth: 4,
    borderColor: "white",
  },
  text: {
    fontSize: 18,
    color: "white",
  },
  tumbContent: {
    width: "100%",
    height: 70,
    backgroundColor: "gray",
  },
  thumb: {
    height: 75,
    width: 75,
    margin: 8,
    borderWidth: 2,
    borderColor: "black",
  },
  mergeButton: {
    backgroundColor: "#4caf50",
    height: 45,
    width: "90%",
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    alignSelf: "center",
    marginBottom: 20,
  },
  mergeButtonText: {
    color: "white",
    fontSize: 18,
    fontWeight: "bold",
  },
});
