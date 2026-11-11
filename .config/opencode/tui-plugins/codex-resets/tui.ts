import { createTextAttributes } from "@opentui/core"
import { createElement, insert, setProp } from "@opentui/solid"
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import { spawn } from "node:child_process"
import { readFileSync } from "node:fs"
import { createSignal } from "solid-js"

import {
  formatAge,
  formatDetails,
  formatExpiry,
  formatTimeUntil,
  parseResetCredits,
  selectExpiringCredit,
  type ExpiryPromptInfo,
  type ResetState,
} from "./lib.ts"

const DEFAULT_ENDPOINT = "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits"
const USAGE_SETTINGS_URL = "https://chatgpt.com/settings/usage"
const BOLD = createTextAttributes({ bold: true })
const DAY_MS = 86_400_000
const TICK_MS = 30_000

interface ExpiryPromptConfig {
  enabled: boolean
  withinMinutes: number
}

interface Config {
  refreshMs: number
  minRefreshMs: number
  timeoutMs: number
  urgentDays: number
  warnDays: number
  endpoint: string
  hideWhenUnavailable: boolean
  expiryPrompt: ExpiryPromptConfig
}

interface OAuthCredentials {
  access: string
  accountId?: string
}

interface UsageContext {
  client: Context["client"]
  env: Record<string, string | undefined>
}

export default Plugin.define({
  id: "opencode-codex-resets",
  async setup(context) {
    const config = normalizeOptions(context.options)
    const expiryPromptState: ExpiryPromptInfo = {
      enabled: config.expiryPrompt.enabled,
      withinMinutes: config.expiryPrompt.withinMinutes,
    }
    const state: ResetState = {
      credits: [],
      fetchedAt: 0,
      missing: false,
      loading: true,
      expiryPrompt: expiryPromptState,
    }

    let refreshing = false
    let disposed = false
    const promptRuntime = {
      prompting: false,
      prompted: new Set<string>(),
    }
    const [getTick, setTick] = createSignal(0)

    const repaint = () => {
      if (disposed) return
      setTick((value) => value + 1)
      context.renderer.requestRender()
    }

    async function refresh(force = false) {
      if (refreshing) return
      if (!force && state.fetchedAt > 0 && Date.now() - state.fetchedAt < config.minRefreshMs) return

      let credentials: OAuthCredentials | undefined
      refreshing = true
      try {
        credentials = await resolveOAuth({ client: context.client, env: process.env })
        if (!credentials) {
          state.credits = []
          state.fetchedAt = 0
          state.error = undefined
          state.missing = true
          return
        }

        state.missing = false
        const payload = await fetchResetCredits(credentials, config)
        state.credits = parseResetCredits(payload)
        state.fetchedAt = Date.now()
        state.error = undefined
      } catch (error) {
        state.error = describeError(error)
      } finally {
        refreshing = false
        state.loading = false
        repaint()
      }

      if (config.expiryPrompt.enabled && !disposed) {
        void maybePromptExpiry()
      }
    }

    async function maybePromptExpiry() {
      if (disposed || promptRuntime.prompting) return
      const credit = selectExpiringCredit(state.credits, Date.now(), config.expiryPrompt.withinMinutes)
      if (!credit?.id || promptRuntime.prompted.has(credit.id)) return

      promptRuntime.prompting = true
      promptRuntime.prompted.add(credit.id)
      try {
        const confirmed = await context.ui.dialog.confirm({
          title: "Codex reset expiring",
          message: `A banked Codex reset expires ${formatTimeUntil(credit.expiresAt)} (${formatExpiry(credit.expiresAt)}).\n\nOpen ChatGPT usage settings to use it?`,
          label: { confirm: "Open settings", cancel: "Not now" },
        })
        if (disposed || !confirmed) return

        openUsageSettings()
        context.ui.toast.show({
          title: "Codex resets",
          message: "Opened ChatGPT usage settings.",
          variant: "info",
          duration: 5_000,
        })
      } catch {
        if (!disposed) {
          context.ui.toast.show({
            title: "Codex resets",
            message: `Couldn't open the browser. Visit ${USAGE_SETTINGS_URL}`,
            variant: "warning",
            duration: 10_000,
          })
        }
      } finally {
        promptRuntime.prompting = false
        repaint()
      }
    }

    function openUsageSettings() {
      const command =
        process.platform === "darwin" ? "open" : process.platform === "win32" ? "cmd" : "xdg-open"
      const args =
        process.platform === "win32" ? ["/c", "start", "", USAGE_SETTINGS_URL] : [USAGE_SETTINGS_URL]
      const child = spawn(command, args, { detached: true, stdio: "ignore" })
      child.on("error", () => {
        if (!disposed) {
          context.ui.toast.show({
            title: "Codex resets",
            message: `Couldn't open the browser. Visit ${USAGE_SETTINGS_URL}`,
            variant: "warning",
            duration: 10_000,
          })
        }
      })
      child.unref()
    }

    const unsubs = [
      context.data.on("credential.updated", () => void refresh(true)),
      context.data.on("session.created", () => void refresh()),
    ]
    const refreshTimer = setInterval(() => void refresh(), config.refreshMs)
    const tickTimer = setInterval(() => {
      repaint()
      if (!config.expiryPrompt.enabled || Date.now() - state.fetchedAt < 60_000) return
      const hot = state.credits.some(
        (credit) =>
          credit.expiresAt > Date.now() &&
          credit.expiresAt - Date.now() <= (config.expiryPrompt.withinMinutes + 5) * 60_000,
      )
      if (hot) void refresh()
    }, TICK_MS)

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "codex-resets.refresh",
          title: "Codex resets: refresh",
          group: "Codex",
          palette: true,
          run: () => {
            context.ui.toast.show({ message: "Refreshing Codex resets…" })
            void refresh(true)
          },
        },
        {
          id: "codex-resets.show",
          title: "Codex resets: show details",
          group: "Codex",
          palette: true,
          slash: { name: "codex-resets" },
          run: async () => {
            await context.ui.dialog.alert({
              title: "Codex resets",
              message: formatDetails(state),
            })
          },
        },
        {
          id: "codex-resets.open",
          title: "Codex resets: open ChatGPT usage settings",
          group: "Codex",
          palette: true,
          run: () => {
            try {
              openUsageSettings()
              context.ui.toast.show({
                title: "Codex resets",
                message: "Opened ChatGPT usage settings.",
                variant: "info",
                duration: 5_000,
              })
            } catch {
              context.ui.toast.show({
                title: "Codex resets",
                message: `Couldn't open the browser. Visit ${USAGE_SETTINGS_URL}`,
                variant: "warning",
                duration: 10_000,
              })
            }
          },
        },
      ],
    }))

    void refresh(true)

    const unregister = context.ui.slot({
      append: "sidebar.content",
      render: () => {
        getTick()
        if (state.missing && config.hideWhenUnavailable) return box({ width: "100%", height: 0 }, [])
        return renderPanel(state, config, context.theme, Date.now())
      },
    })

    return () => {
      disposed = true
      for (const unsubscribe of unsubs) unsubscribe()
      clearInterval(refreshTimer)
      clearInterval(tickTimer)
      unregister()
    }
  },
})

async function fetchResetCredits(credentials: OAuthCredentials, config: Config): Promise<unknown> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), config.timeoutMs)
  try {
    const response = await fetch(config.endpoint, {
      headers: {
        Authorization: `Bearer ${credentials.access}`,
        Accept: "application/json",
        "User-Agent": "codex-cli",
        ...(credentials.accountId ? { "ChatGPT-Account-Id": credentials.accountId } : {}),
      },
      signal: controller.signal,
    })
    if (!response.ok) {
      if (response.status === 401 || response.status === 403) {
        throw new Error(`auth expired (HTTP ${response.status}) — reconnect OpenAI in /connect`)
      }
      throw new Error(`HTTP ${response.status}`)
    }
    return await response.json()
  } finally {
    clearTimeout(timer)
  }
}

async function resolveOAuth(context: UsageContext): Promise<OAuthCredentials | undefined> {
  try {
    const listed = await context.client.credential.list()
    const entries = Array.isArray(listed) ? listed : (listed as { data?: unknown })?.data
    if (Array.isArray(entries)) {
      const candidates = entries.filter(
        (entry): entry is Record<string, any> =>
          isRecord(entry) &&
          entry["integrationID"] === "openai" &&
          isRecord(entry["value"]) &&
          entry["value"]["type"] === "oauth" &&
          typeof entry["value"]["access"] === "string",
      )
      const entry = candidates.find((candidate) => candidate["active"]) ?? candidates[0]
      if (entry) {
        return {
          access: entry["value"]["access"],
          ...accountIdOf(entry["value"]["metadata"]),
        }
      }
    }
  } catch {
    // Fall through to the legacy auth file.
  }

  const content = context.env["OPENCODE_AUTH_CONTENT"]
  if (content) {
    try {
      const credentials = asOAuth(JSON.parse(content)?.openai)
      if (credentials) return credentials
    } catch {
      // Ignore malformed injected auth content.
    }
  }

  for (const dir of candidateAuthDirs()) {
    try {
      const credentials = asOAuth(JSON.parse(readFileSync(`${dir}/auth.json`, "utf8"))?.openai)
      if (credentials) return credentials
    } catch {
      // Try the next candidate directory.
    }
  }

  return undefined
}

function asOAuth(value: unknown): OAuthCredentials | undefined {
  if (!isRecord(value) || value["type"] !== "oauth" || typeof value["access"] !== "string") return undefined
  return {
    access: value["access"],
    ...accountIdOf(value),
  }
}

function accountIdOf(value: unknown): { accountId?: string } {
  if (!isRecord(value)) return {}
  const accountId = value["accountID"] ?? value["accountId"]
  return typeof accountId === "string" ? { accountId } : {}
}

function candidateAuthDirs(): string[] {
  const dirs: string[] = []
  const seen = new Set<string>()
  const push = (dir: string | undefined) => {
    if (!dir || seen.has(dir)) return
    seen.add(dir)
    dirs.push(dir)
  }

  if (process.env.XDG_DATA_HOME) push(`${process.env.XDG_DATA_HOME}/opencode`)
  if (process.env.HOME) {
    push(`${process.env.HOME}/.local/share/opencode`)
    push(`${process.env.HOME}/Library/Application Support/opencode`)
  }
  if (process.platform === "win32" && process.env.APPDATA) push(`${process.env.APPDATA}/opencode`)
  return dirs
}

function renderPanel(state: ResetState, config: Config, theme: Context["theme"], now: number) {
  const lines = buildLines(state, config, theme, now)
  return box(
    { width: "100%", flexDirection: "column" },
    lines.map((line) =>
      box({ flexDirection: "row", width: "100%", justifyContent: "space-between" }, [
        box(
          { flexDirection: "row" },
          line.parts.map((part) =>
            text(
              {
                fg: part.fg,
                ...(part.bold ? { attributes: BOLD } : {}),
                ...(part.width !== undefined ? { width: part.width, flexShrink: 0, wrapMode: "none" } : {}),
              },
              [truncate(part.text)],
            ),
          ),
        ),
        ...(line.right
          ? [
              box(
                { flexDirection: "row" },
                line.right.map((part) =>
                  text(
                    {
                      fg: part.fg,
                      ...(part.width !== undefined ? { width: part.width, flexShrink: 0, wrapMode: "none" } : {}),
                    },
                    [truncate(part.text)],
                  ),
                ),
              ),
            ]
          : []),
      ]),
    ),
  )
}

interface LinePart {
  text: string
  fg?: string
  bold?: boolean
  width?: number
}

interface Line {
  parts: LinePart[]
  right?: LinePart[]
}

function buildLines(state: ResetState, config: Config, theme: Context["theme"], now: number): Line[] {
  const header: Line = {
    parts: [{ text: "Codex resets", fg: theme.text.base, bold: true }],
    ...(config.expiryPrompt.enabled
      ? { right: [{ text: `prompt ${config.expiryPrompt.withinMinutes}m`, fg: theme.text.muted }] }
      : {}),
  }
  const lines: Line[] = [header]
  const count = state.credits.length

  if (state.missing) {
    lines.push({ parts: [{ text: "not connected", fg: theme.text.muted }] })
    lines.push({ parts: [{ text: "connect OpenAI in /connect", fg: theme.text.muted }] })
    return lines
  }

  if (state.loading && count === 0) {
    lines.push({ parts: [{ text: "loading…", fg: theme.text.muted }] })
    return lines
  }

  const summary = count > 0 ? `${count} available` : state.error ? "unavailable" : "No banked resets"
  lines.push({
    parts: [{ text: summary, fg: theme.text.muted }],
    ...(state.fetchedAt > 0
      ? { right: [{ text: `updated ${formatAge(now - state.fetchedAt)}`, fg: theme.text.muted }] }
      : {}),
  })

  if (state.error && count === 0) {
    lines.push({ parts: [{ text: state.error, fg: theme.text.muted }] })
    return lines
  }

  state.credits.forEach((credit) => {
    const color = expiryColor(credit.expiresAt, now, config, theme)
    lines.push({
      parts: [{ text: formatExpiry(credit.expiresAt), fg: theme.text.base }],
      right: [{ text: ` ${formatTimeUntil(credit.expiresAt, now)}`, fg: color, width: 11 }],
    })
  })

  if (state.error) {
    lines.push({ parts: [{ text: `last refresh failed: ${state.error}`, fg: theme.text.muted }] })
  }

  return lines
}

function expiryColor(expiresAt: number, now: number, config: Config, theme: Context["theme"]): string {
  const days = (expiresAt - now) / DAY_MS
  if (days <= config.urgentDays) return theme.text.feedback.error.base
  if (days <= config.warnDays) return theme.text.feedback.warning.base
  return theme.text.muted
}

function normalizeOptions(raw: unknown): Config {
  const options = isRecord(raw) ? raw : {}
  const expiryPrompt = isRecord(options["expiryPrompt"]) ? options["expiryPrompt"] : {}
  return {
    refreshMs: positiveInt(options["refreshMs"], 300_000),
    minRefreshMs: positiveInt(options["minRefreshMs"], 30_000),
    timeoutMs: positiveInt(options["timeoutMs"], 10_000),
    urgentDays: positiveNumber(options["urgentDays"], 2),
    warnDays: positiveNumber(options["warnDays"], 7),
    endpoint:
      typeof options["endpoint"] === "string" && options["endpoint"].trim()
        ? options["endpoint"].trim()
        : DEFAULT_ENDPOINT,
    hideWhenUnavailable: options["hideWhenUnavailable"] !== false,
    expiryPrompt: {
      enabled: expiryPrompt["enabled"] === true,
      withinMinutes: positiveNumber(expiryPrompt["withinMinutes"], 15),
    },
  }
}

function describeError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error)
  return message.length <= 100 ? message : `${message.slice(0, 99)}…`
}

function positiveInt(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : fallback
}

function positiveNumber(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : fallback
}

function isRecord(value: unknown): value is Record<string, any> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function truncate(value: string, max = 60): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`
}

// OpenTUI renderables are not DOM nodes, while the slot contract types JSX.Element
// as one. The usage plugin this is modelled on uses the same runtime helpers.
function element(tag: string, props: Record<string, unknown>, children: unknown[] = []): any {
  const node = createElement(tag)
  for (const [key, value] of Object.entries(props)) {
    if (value !== undefined) setProp(node, key, value)
  }
  for (const child of children) {
    if (child !== null && child !== undefined && child !== false) insert(node, child)
  }
  return node
}

function text(props: Record<string, unknown>, children: unknown[] = []): any {
  return element("text", props, children)
}

function box(props: Record<string, unknown>, children: unknown[] = []): any {
  return element("box", props, children)
}
