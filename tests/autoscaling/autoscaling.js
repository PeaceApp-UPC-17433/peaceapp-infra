// Prueba de autoescalado en AKS (4.4.3). SOLO LECTURAS con una cuenta QA preexistente: no crea datos ni envía
// correos. Rampa -> meseta -> bajada; el workflow muestrea el HPA en paralelo.
// Seguridad: aborta sola si los errores superan el 10 % (no se insiste sobre producción caída).
import http from 'k6/http'
import { check, sleep } from 'k6'

const BASE = __ENV.BASE_URL || 'https://api.peaceapp.angelanampa.dev'
const PEAK = Math.min(Number(__ENV.PEAK_VUS || 40), 50)
const MINUTES = Math.min(Number(__ENV.DURATION_MINUTES || 10), 15)
const AREA = 'minLat=-12.2&maxLat=-11.9&minLng=-77.2&maxLng=-76.9'

export const options = {
    scenarios: {
        rampa: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { target: PEAK, duration: '2m' },
                { target: PEAK, duration: `${Math.max(MINUTES - 4, 1)}m` },
                { target: 0, duration: '2m' }
            ],
            gracefulRampDown: '10s'
        }
    },
    thresholds: {
        http_req_failed: [{ threshold: 'rate<0.10', abortOnFail: true, delayAbortEval: '30s' }],
        'http_req_duration{scenario:rampa}': ['p(95)<2000']
    },
    summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max']
}

export function setup() {
    const res = http.post(`${BASE}/api/v1/auth/login`, JSON.stringify({ email: __ENV.QA_EMAIL, password: __ENV.QA_PASSWORD }), {
        headers: { 'Content-Type': 'application/json' }
    })
    if (res.status !== 200) throw new Error(`login QA falló: HTTP ${res.status}`)
    return { token: res.json('accessToken') }
}

export default function (data) {
    const params = (name) => ({ headers: { Authorization: `Bearer ${data.token}` }, tags: { name } })
    const list = http.get(`${BASE}/api/v1/incidents?page=0&size=12&sortBy=createdAt&direction=desc`, params('GET /incidents'))
    const map = http.get(`${BASE}/api/v1/incidents/map?${AREA}`, params('GET /incidents/map'))
    const heat = http.get(`${BASE}/api/v1/incidents/heatmap?${AREA}&cellSize=0.01`, params('GET /incidents/heatmap'))
    check(list, { 'listado 200': (r) => r.status === 200 })
    check(map, { 'mapa 200': (r) => r.status === 200 })
    check(heat, { 'heatmap 200': (r) => r.status === 200 })
    sleep(1)
}
