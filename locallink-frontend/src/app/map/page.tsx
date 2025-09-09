"use client";

import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { useState, useEffect } from "react";
import { fetchJobs, fetchEvents } from "../../services/api";

const jobIcon = new L.Icon({
  iconUrl: "https://cdn-icons-png.flaticon.com/512/1483/1483336.png",
  iconSize: [32, 32],
  iconAnchor: [16, 32],
});

const eventIcon = new L.Icon({
  iconUrl: "https://cdn-icons-png.flaticon.com/512/684/684908.png",
  iconSize: [32, 32],
  iconAnchor: [16, 32],
});

export default function MapPage() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [events, setEvents] = useState<any[]>([]);
  const [selected, setSelected] = useState<any>(null);

  useEffect(() => {
    async function loadData() {
      try {
        const jobsData = await fetchJobs();
        const eventsData = await fetchEvents();
        setJobs(jobsData);
        setEvents(eventsData);
      } catch (err) {
        console.error("Error loading data:", err);
      }
    }
    loadData();
  }, []);

  return (
    <div className="w-full h-screen relative">
      <MapContainer
        center={[41.3275, 69.2817]}
        zoom={14}
        style={{ width: "100%", height: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://osm.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {jobs.map((job) => (
          <Marker
            key={`job-${job.id}`}
            position={[job.lat, job.lng]}
            icon={jobIcon}
            eventHandlers={{
              click: () => setSelected(job),
            }}
          >
            <Popup>{job.title}</Popup>
          </Marker>
        ))}

        {events.map((event) => (
          <Marker
            key={`event-${event.id}`}
            position={[event.lat, event.lng]}
            icon={eventIcon}
            eventHandlers={{
              click: () => setSelected(event),
            }}
          >
            <Popup>{event.title}</Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Карточка выбранного объекта */}
      {selected && (
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-white p-4 rounded-2xl shadow-lg w-11/12 max-w-md">
          <h2 className="text-lg font-semibold">{selected.title}</h2>
          <p className="text-sm text-gray-600">{selected.category}</p>
          <div className="flex justify-between mt-2">
            <span className="text-blue-600 font-bold">{selected.distance ?? "—"}</span>
            <span className="text-green-600">{selected.price ?? ""}</span>
          </div>
        </div>
      )}
    </div>
  );
}
