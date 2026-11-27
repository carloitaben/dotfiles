// Holds every fetch/XHR request of every browser page for <ms> before letting it through,
// so loading states last long enough to see on video. Runs until killed.
// Usage: node delay.mjs <browser-ws-url> <ms>
const [url, ms] = [process.argv[2], Number(process.argv[3])]
const ws = new WebSocket(url)
let id = 0
const send = (method, params = {}, sessionId) =>
  ws.send(JSON.stringify({ id: ++id, method, params, sessionId }))
const attached = new Set()

ws.onopen = () => {
  send("Target.setDiscoverTargets", { discover: true })
  send("Target.setAutoAttach", {
    autoAttach: true,
    waitForDebuggerOnStart: false,
    flatten: true,
  })
  console.log("delay up")
}

ws.onmessage = ({ data }) => {
  const m = JSON.parse(data)
  if (m.method === "Target.targetCreated" && m.params.targetInfo.type === "page") {
    send("Target.attachToTarget", { targetId: m.params.targetInfo.targetId, flatten: true })
  }
  if (m.method === "Target.attachedToTarget") {
    const { sessionId, targetInfo } = m.params
    if (targetInfo.type !== "page" || attached.has(sessionId)) return
    attached.add(sessionId)
    send(
      "Fetch.enable",
      { patterns: [{ resourceType: "XHR" }, { resourceType: "Fetch" }] },
      sessionId,
    )
  }
  if (m.method === "Fetch.requestPaused") {
    setTimeout(
      () => send("Fetch.continueRequest", { requestId: m.params.requestId }, m.sessionId),
      ms,
    )
  }
}
