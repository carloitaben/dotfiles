export interface ResetCredit {
  id?: string
  title?: string
  status?: string
  grantedAt?: number
  expiresAt: number
}

export interface ExpiryPromptInfo {
  enabled: boolean
  withinMinutes: number
}

export interface ResetState {
  credits: ResetCredit[]
  fetchedAt: number
  error?: string
  missing: boolean
  loading: boolean
  expiryPrompt?: ExpiryPromptInfo
}

export function parseResetCredits(payload: unknown): ResetCredit[] {
  if (!isRecord(payload)) return []
  const raw = Array.isArray(payload["credits"]) ? payload["credits"] : []
  const credits: ResetCredit[] = []

  for (const item of raw) {
    if (!isRecord(item)) continue
    const status = typeof item["status"] === "string" ? item["status"] : "available"
    if (status !== "available") continue
    const expiresAt = parseMs(item["expires_at"])
    if (expiresAt === undefined) continue
    credits.push({
      ...(typeof item["id"] === "string" ? { id: item["id"] } : {}),
      ...(typeof item["title"] === "string" ? { title: item["title"] } : {}),
      status,
      ...(parseMs(item["granted_at"]) !== undefined ? { grantedAt: parseMs(item["granted_at"]) } : {}),
      expiresAt,
    })
  }

  return credits.toSorted((left, right) => left.expiresAt - right.expiresAt)
}

export function selectExpiringCredit(
  credits: ResetCredit[],
  now: number,
  withinMinutes: number,
): ResetCredit | undefined {
  const windowMs = withinMinutes * 60_000
  return credits
    .filter(
      (credit) =>
        typeof credit.id === "string" &&
        credit.id.length > 0 &&
        credit.expiresAt > now &&
        credit.expiresAt - now <= windowMs,
    )
    .toSorted((left, right) => left.expiresAt - right.expiresAt)[0]
}

export function formatAge(ms: number): string {
  if (ms < 60_000) return "just now"
  const minutes = Math.floor(ms / 60_000)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  return `${Math.floor(hours / 24)}d ago`
}

export function formatTimeUntil(expiresAt: number, now = Date.now()): string {
  const diff = expiresAt - now
  if (diff <= 0) return "expired"
  const seconds = Math.floor(diff / 1_000)
  if (seconds < 3_600) return `in ${Math.max(1, Math.floor(seconds / 60))}m`
  if (seconds < 86_400) return `in ${Math.floor(seconds / 3_600)}h`
  const days = Math.floor(seconds / 86_400)
  const hours = Math.floor((seconds % 86_400) / 3_600)
  return hours > 0 && days < 7 ? `in ${days}d ${hours}h` : `in ${days}d`
}

export function formatExpiry(expiresAt: number): string {
  const date = new Date(expiresAt)
  const now = new Date()
  const sameYear = date.getFullYear() === now.getFullYear()
  const day = new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    ...(sameYear ? {} : { year: "numeric" }),
  }).format(date)
  const time = new Intl.DateTimeFormat(undefined, {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date)
  return `${time} ${day}`
}

export function formatDateTime(ms: number): string {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(ms))
}

export function formatDetails(state: ResetState, now = Date.now()): string {
  if (state.missing) return "No OpenAI OAuth credential. Connect OpenAI in /connect."

  const count = state.credits.length
  const lines: string[] = []
  if (count === 0) {
    lines.push("No banked resets available.")
  } else {
    lines.push(`${count} banked reset${count === 1 ? "" : "s"} available.`)
    state.credits.forEach((credit, index) => {
      lines.push("")
      lines.push(`#${index + 1} ${credit.title ?? "Codex reset"}`)
      lines.push(`  expires ${formatDateTime(credit.expiresAt)} (${formatTimeUntil(credit.expiresAt, now)})`)
      if (credit.grantedAt !== undefined) lines.push(`  granted ${formatDateTime(credit.grantedAt)}`)
    })
  }

  if (state.error) {
    lines.push("")
    lines.push(`Last refresh failed: ${state.error}`)
  }
  if (state.fetchedAt > 0) {
    lines.push("")
    lines.push(`Updated ${formatAge(now - state.fetchedAt)}.`)
  }
  if (count > 0) {
    lines.push("")
    lines.push("Use resets at https://chatgpt.com/settings/usage.")
  }
  if (state.expiryPrompt?.enabled) {
    lines.push("")
    lines.push(`Expiry reminder: on, ${state.expiryPrompt.withinMinutes}m before expiry.`)
  }
  return lines.join("\n")
}

function parseMs(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value < 1e12 ? value * 1_000 : value
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Date.parse(value)
    return Number.isFinite(parsed) ? parsed : undefined
  }
  return undefined
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
