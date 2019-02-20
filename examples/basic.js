import React, { Component } from "react";
import { View } from "react-native";
import Eddystone from "@lg2/react-native-eddystone";

export default class App extends Component {
  componentDidMount() {
    // bind eddystone events
    Eddystone.addListener("onUIDFrame", this.onUID);
    Eddystone.addListener("onEIDFrame", this.onEID);
    Eddystone.addListener("onURLFrame", this.onUrl);
    Eddystone.addListener("onTelemetryFrame", this.onTelemetry);
    Eddystone.addListener("onEmptyFrame", this.onEmptyFrame);
    Eddystone.addListener("onStateChanged", this.onStateChanged);

    // start listening for eddystone beacon events
    Eddystone.startScanning();
  }

  onUID(beacon) {
    console.log("UID Beacon:", beacon);
  }

  onEID(beacon) {
    console.log("EID Beacon:", beacon);
  }

  onUrl(url) {
    console.log("URL:", url);
  }

  onTelemetry(telemetry) {
    console.log("Telemetry:", telemetry);
  }

  onStateChanged(state) {
    console.log(`state: ${state}`);
  }

  render() {
    return <View />;
  }
}