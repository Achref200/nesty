"use client";

import { useState } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// Default centre: Tunis. Agencies pan/zoom and tap to drop the exact pin.
const TUNIS: [number, number] = [36.8065, 10.1815];

// A monochrome ink pin — avoids Leaflet's default (broken) marker asset.
const PIN = L.divIcon({
  className: "",
  html:
    '<div style="width:22px;height:22px;border-radius:50% 50% 50% 0;' +
    "background:#141414;transform:rotate(-45deg);border:2px solid #fff;" +
    'box-shadow:0 4px 10px rgba(0,0,0,.3)"></div>',
  iconSize: [22, 22],
  iconAnchor: [11, 22],
});

function ClickCapture({
  onPick,
}: {
  onPick: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

/** Interactive map that captures the property's exact latitude & longitude. */
export function LocationPicker() {
  const [pos, setPos] = useState<[number, number] | null>(null);

  return (
    <div>
      <div className="h-64 w-full overflow-hidden rounded-2xl border border-separator">
        <MapContainer
          center={TUNIS}
          zoom={12}
          scrollWheelZoom={false}
          style={{ height: "100%", width: "100%" }}
        >
          <TileLayer
            attribution='&copy; OpenStreetMap contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <ClickCapture onPick={(lat, lng) => setPos([lat, lng])} />
          {pos && <Marker position={pos} icon={PIN} />}
        </MapContainer>
      </div>
      <input type="hidden" name="latitude" value={pos ? pos[0] : ""} />
      <input type="hidden" name="longitude" value={pos ? pos[1] : ""} />
      <p className="mt-2 text-[13px] text-muted">
        {pos
          ? `Pinned at ${pos[0].toFixed(5)}, ${pos[1].toFixed(5)}`
          : "Tap the map to drop the exact pin for this property."}
      </p>
    </div>
  );
}
