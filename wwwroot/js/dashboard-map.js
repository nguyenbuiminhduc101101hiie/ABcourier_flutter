const LEAFLET_SCRIPT_ID = "dashboard-leaflet-script";
const LEAFLET_STYLESHEET_ID = "dashboard-leaflet-stylesheet";
const LEAFLET_SCRIPT_URL = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
const LEAFLET_STYLESHEET_URL = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";

let dashboardMap = null;
let dashboardMarkers = [];
let routePolylines = [];
let leafletLoadPromise = null;
let resizeListenerAttached = false;

function ensureLeafletStylesheet() {
    if (document.getElementById(LEAFLET_STYLESHEET_ID)) return;

    const stylesheet = document.createElement("link");
    stylesheet.id = LEAFLET_STYLESHEET_ID;
    stylesheet.rel = "stylesheet";
    stylesheet.href = LEAFLET_STYLESHEET_URL;
    stylesheet.integrity = "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=";
    stylesheet.crossOrigin = "";
    document.head.appendChild(stylesheet);
}

function ensureLeafletLoaded() {
    ensureLeafletStylesheet();

    if (window.L) return Promise.resolve(window.L);
    if (leafletLoadPromise) return leafletLoadPromise;

    leafletLoadPromise = new Promise((resolve, reject) => {
        const onLoad = () => {
            if (window.L) {
                resolve(window.L);
            } else {
                leafletLoadPromise = null;
                reject(new Error("Leaflet đã tải nhưng không tạo window.L."));
            }
        };

        const onError = () => {
            leafletLoadPromise = null;
            reject(new Error("Không thể tải Leaflet từ CDN."));
        };

        const existingScript = document.getElementById(LEAFLET_SCRIPT_ID);
        if (existingScript) {
            existingScript.addEventListener("load", onLoad, { once: true });
            existingScript.addEventListener("error", onError, { once: true });
            return;
        }

        const script = document.createElement("script");
        script.id = LEAFLET_SCRIPT_ID;
        script.src = LEAFLET_SCRIPT_URL;
        script.integrity = "sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=";
        script.crossOrigin = "";
        script.addEventListener("load", onLoad, { once: true });
        script.addEventListener("error", onError, { once: true });
        document.head.appendChild(script);
    });

    return leafletLoadPromise;
}

export function resizeDashboardCharts() {
    try {
        const selectors = ".profit-chart-wrapper svg, .profit-chart-wrapper canvas, .shipment-chart-wrapper canvas, .shipment-chart-wrapper svg";
        document.querySelectorAll(selectors).forEach(element => {
            const holder = element.closest(".profit-chart-wrapper, .shipment-chart-wrapper");
            if (!holder) return;

            const rect = holder.getBoundingClientRect();
            if (rect.width > 0 && rect.height > 0) {
                element.style.width = "100%";
                element.style.height = `${rect.height}px`;
                element.style.maxHeight = `${rect.height}px`;
            }
        });
        setTimeout(() => window.dispatchEvent(new Event("resize")), 50);
    } catch (error) {
        console.warn("resizeDashboardCharts error:", error);
    }
}

function resizeDashboardMapSquare() {
    const mapElement = document.getElementById("dashboardMap");
    if (!mapElement) return;

    const holder = mapElement.parentElement;
    const width = holder ? holder.clientWidth : mapElement.clientWidth;
    if (width > 0) {
        mapElement.style.display = "block";
        mapElement.style.width = "100%";
        mapElement.style.height = `${width}px`;
        mapElement.style.minHeight = "320px";
        mapElement.style.position = "relative";
    }
}

function handleWindowResize() {
    resizeDashboardMapSquare();
    if (dashboardMap) {
        setTimeout(() => dashboardMap?.invalidateSize(), 100);
    }
}

function attachResizeListener() {
    if (resizeListenerAttached) return;
    window.addEventListener("resize", handleWindowResize);
    resizeListenerAttached = true;
}

function removeMapInstance() {
    dashboardMarkers = [];
    routePolylines = [];

    if (dashboardMap) {
        dashboardMap.remove();
        dashboardMap = null;
    }
}

async function initDashboardMap() {
    const mapElement = document.getElementById("dashboardMap");
    if (!mapElement) {
        console.warn("Không tìm thấy div #dashboardMap để khởi tạo bản đồ");
        return false;
    }

    try {
        await ensureLeafletLoaded();

        if (dashboardMap) {
            if (dashboardMap.getContainer() === mapElement) {
                setTimeout(() => dashboardMap?.invalidateSize(), 150);
                return true;
            }

            // Blazor đã thay DOM của tab; bỏ instance gắn với node cũ trước khi tạo lại.
            removeMapInstance();
        }

        const leaflet = window.L;
        dashboardMap = leaflet.map(mapElement, {
            zoomControl: true,
            preferCanvas: true
        }).setView([10.7769, 106.7009], 12);

        leaflet.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
            attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19
        }).addTo(dashboardMap);

        attachResizeListener();
        setTimeout(() => dashboardMap?.invalidateSize(), 250);
        console.log("Dashboard map initialized successfully with Leaflet");
        return true;
    } catch (error) {
        console.error("Error initializing dashboard map:", error);
        mapElement.innerHTML = `
            <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;background:#f5f5f5;border-radius:18px;padding:20px;text-align:center;">
                <h3 style="color:#d32f2f;margin-bottom:10px;">⚠️ Lỗi Leaflet Map</h3>
                <p style="color:#666;margin-bottom:10px;">Không thể khởi tạo bản đồ</p>
                <p style="color:#666;font-size:14px;">Vui lòng kiểm tra console hoặc kết nối internet</p>
                <button onclick="location.reload()" style="margin-top:10px;padding:8px 16px;background:#1976d2;color:white;border:none;border-radius:4px;cursor:pointer;">Thử lại</button>
            </div>`;
        return false;
    }
}

export async function ensureDashboardMap() {
    resizeDashboardMapSquare();

    const initialized = await initDashboardMap();
    if (initialized && dashboardMap) {
        [100, 300, 700].forEach(delay => {
            setTimeout(() => {
                resizeDashboardMapSquare();
                dashboardMap?.invalidateSize();
            }, delay);
        });
    }

    return initialized;
}

function removeMapLayers() {
    if (!dashboardMap) return;

    dashboardMarkers.forEach(marker => dashboardMap.removeLayer(marker));
    dashboardMarkers = [];
    routePolylines.forEach(polyline => dashboardMap.removeLayer(polyline));
    routePolylines = [];
}

export async function loadDashboardMapMarkers(jsonLocations, hblGroupsJson) {
    if (!dashboardMap && !(await ensureDashboardMap())) {
        console.error("Dashboard map chưa được khởi tạo!");
        return;
    }

    setTimeout(() => dashboardMap?.invalidateSize(), 100);

    let locations;
    let hblGroups = {};
    try {
        locations = JSON.parse(jsonLocations);
        if (hblGroupsJson) hblGroups = JSON.parse(hblGroupsJson);
    } catch (error) {
        console.error("Lỗi khi parse JSON:", error);
        return;
    }

    removeMapLayers();
    clearMapInfoPanel();

    if (!Array.isArray(locations) || locations.length === 0) {
        console.log("Không có dữ liệu vị trí để hiển thị");
        return;
    }

    const leaflet = window.L;
    const validMarkers = [];
    const hblColors = ["#ff4444", "#4285f4", "#44ff44", "#ff9800", "#9c27b0", "#00bcd4", "#4caf50", "#f44336"];
    const hblColorMap = {};

    Object.keys(hblGroups).forEach((hblNo, index) => {
        hblColorMap[hblNo] = hblColors[index % hblColors.length];
    });

    Object.keys(hblGroups).forEach(hblNo => {
        const hblLocations = hblGroups[hblNo];
        const hblColor = hblColorMap[hblNo];

        hblLocations.forEach((location, index) => {
            const lat = parseFloat(location.Latitude);
            const lng = parseFloat(location.Longitude);

            if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                console.warn(`Tọa độ không hợp lệ cho HBL ${hblNo}: lat=${lat}, lng=${lng}`);
                return;
            }

            try {
                const customIcon = leaflet.divIcon({
                    className: "custom-div-icon",
                    html: `
                        <div style="background-color:${hblColor};width:40px;height:40px;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;font-size:14px;box-shadow:0 2px 6px rgba(0,0,0,0.3);${index === 0 ? "animation:pulse 2s infinite;" : ""}">
                            ${index + 1}
                        </div>`,
                    iconSize: [40, 40],
                    iconAnchor: [20, 20]
                });

                const marker = leaflet.marker([lat, lng], { icon: customIcon });
                const popupContent = `
                    <div class="custom-popup">
                        <h4 style="border-bottom-color:${hblColor};">${hblNo} - Node ${index + 1}</h4>
                        <p><strong>Thời gian:</strong> ${new Date(location.ngay).toLocaleString("vi-VN")}</p>
                        <p><strong>Tọa độ:</strong> ${lat.toFixed(6)}, ${lng.toFixed(6)}</p>
                        <p><strong>HBL No:</strong> ${location.HBLNo || "N/A"}</p>
                        ${location.Accuracy ? `<p><strong>Độ chính xác:</strong> ${location.Accuracy}m</p>` : ""}
                        ${location.Speed ? `<p><strong>Tốc độ:</strong> ${location.Speed} km/h</p>` : ""}
                        <div style="margin-top:10px;padding:5px;background:${hblColor}20;border-left:3px solid ${hblColor};">
                            <small style="color:#666;">Màu sắc: ${hblColor}</small>
                        </div>
                    </div>`;

                marker.bindPopup(popupContent);
                marker.addTo(dashboardMap);
                dashboardMarkers.push(marker);
                validMarkers.push(marker);

                if (index === 0) {
                    setTimeout(() => {
                        if (dashboardMap?.hasLayer(marker)) marker.openPopup();
                    }, 1000);
                }
            } catch (error) {
                console.error(`Lỗi khi tạo marker cho HBL ${hblNo}:`, error);
            }
        });

        if (hblLocations.length > 1) {
            const coordinates = hblLocations
                .filter(location => {
                    const lat = parseFloat(location.Latitude);
                    const lng = parseFloat(location.Longitude);
                    return !isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
                })
                .map(location => [parseFloat(location.Latitude), parseFloat(location.Longitude)]);

            if (coordinates.length > 1) {
                const polyline = leaflet.polyline(coordinates, {
                    color: hblColor,
                    weight: 4,
                    opacity: 0.8,
                    smoothFactor: 1
                }).addTo(dashboardMap);
                routePolylines.push(polyline);
            }
        }
    });

    if (validMarkers.length > 0) {
        showAllMarkersInfo(hblGroups, hblColorMap);
        const group = new leaflet.featureGroup(validMarkers);
        dashboardMap.fitBounds(group.getBounds().pad(0.1));
    } else {
        console.warn("Không có marker hợp lệ nào được tạo");
    }
}

function showAllMarkersInfo(hblGroups, hblColorMap) {
    const allMarkersInfo = [];

    Object.keys(hblGroups).forEach(hblNo => {
        hblGroups[hblNo].forEach((location, index) => {
            const lat = parseFloat(location.Latitude);
            const lng = parseFloat(location.Longitude);
            if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                allMarkersInfo.push({
                    hblNo,
                    nodeIndex: index + 1,
                    lat,
                    lng,
                    time: new Date(location.ngay).toLocaleString("vi-VN"),
                    hblColor: hblColorMap[hblNo],
                    accuracy: location.Accuracy,
                    speed: location.Speed
                });
            }
        });
    });

    allMarkersInfo.sort((a, b) => new Date(a.time) - new Date(b.time));

    const allInfoContent = `
        <div class="map-info-panel">
            <h3>📍 Thông tin tất cả vị trí (${allMarkersInfo.length} điểm)</h3>
            <div style="display:flex;flex-direction:column;gap:10px;">
                ${allMarkersInfo.map((info, index) => `
                    <div class="location-item" style="border-color:${info.hblColor};background:${info.hblColor}10;">
                        <div class="location-header">
                            <h4 class="location-title" style="color:${info.hblColor};">${info.hblNo} - Node ${info.nodeIndex}</h4>
                            <span class="location-number" style="background:${info.hblColor};">#${index + 1}</span>
                        </div>
                        <div class="location-details">
                            <p><strong>🕒 Thời gian:</strong> ${info.time}</p>
                            <p><strong>📍 Tọa độ:</strong> ${info.lat.toFixed(6)}, ${info.lng.toFixed(6)}</p>
                            ${info.accuracy ? `<p><strong>🎯 Độ chính xác:</strong> ${info.accuracy}m</p>` : ""}
                            ${info.speed ? `<p><strong>🚀 Tốc độ:</strong> ${info.speed} km/h</p>` : ""}
                        </div>
                    </div>`).join("")}
            </div>
            <div style="margin-top:15px;padding:10px;background:#e3f2fd;border-radius:8px;text-align:center;">
                <small style="color:#1976d2;font-weight:bold;">✨ Sử dụng OpenStreetMap miễn phí!</small>
            </div>
        </div>`;

    const infoDiv = document.createElement("div");
    infoDiv.id = "map-info-panel";
    infoDiv.innerHTML = allInfoContent;

    const closeButton = document.createElement("button");
    closeButton.innerHTML = "✕";
    closeButton.className = "close-button";
    closeButton.onclick = () => infoDiv.remove();
    infoDiv.appendChild(closeButton);

    document.getElementById("dashboardMap")?.parentElement?.appendChild(infoDiv);
}

function setDashboardTileLayer(styleType) {
    if (!dashboardMap || !window.L) return;

    dashboardMap.eachLayer(layer => {
        if (layer instanceof window.L.TileLayer) dashboardMap.removeLayer(layer);
    });

    let tileLayer;
    switch (styleType) {
        case "satellite":
        case "hybrid":
            tileLayer = window.L.tileLayer("https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}", {
                attribution: "© Esri",
                maxZoom: 19
            });
            break;
        case "terrain":
            tileLayer = window.L.tileLayer("https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png", {
                attribution: "© OpenTopoMap",
                maxZoom: 17
            });
            break;
        case "traffic":
            tileLayer = window.L.tileLayer("https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png", {
                attribution: "© OpenStreetMap HOT contributors",
                maxZoom: 19
            });
            break;
        default:
            tileLayer = window.L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                attribution: "© OpenStreetMap contributors",
                maxZoom: 19
            });
            break;
    }

    tileLayer.addTo(dashboardMap);
    setTimeout(() => dashboardMap?.invalidateSize(), 100);
}

export async function changeMapStyle(styleType) {
    if (!dashboardMap && !(await ensureDashboardMap())) return;
    setDashboardTileLayer(styleType || "roadmap");
}

export async function toggleTrafficLayer(show) {
    if (!dashboardMap && !(await ensureDashboardMap())) return;
    setDashboardTileLayer(show ? "traffic" : "roadmap");
}

export function clearMapInfoPanel() {
    document.getElementById("map-info-panel")?.remove();
}

export function closeAllPopups() {
    dashboardMap?.closePopup();
}

export function disposeDashboardMap() {
    clearMapInfoPanel();
    removeMapLayers();
    removeMapInstance();

    if (resizeListenerAttached) {
        window.removeEventListener("resize", handleWindowResize);
        resizeListenerAttached = false;
    }
}
