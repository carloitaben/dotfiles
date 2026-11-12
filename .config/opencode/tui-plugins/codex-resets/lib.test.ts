import { describe, expect, test } from "bun:test"

import {
  formatAge,
  formatDetails,
  formatExpiry,
  formatTimeUntil,
  parseResetCredits,
  selectExpiringCredit,
  type ResetState,
} from "./lib.ts"

const payload = {
  credits: [
    {
      id: "b",
      status: "available",
      title: "Full reset (Weekly + 5 hr)",
      granted_at: "2026-11-01T20:37:31.638784Z",
      expires_at: "2026-12-01T20:37:31.638784Z",
    },
    {
      id: "a",
      status: "available",
      title: "Full reset (Weekly + 5 hr)",
      granted_at: "2026-10-31T19:55:01.428104Z",
      expires_at: "2026-11-30T19:55:01.428104Z",
    },
    {
      id: "used",
      status: "redeemed",
      expires_at: "2026-12-02T00:00:00Z",
    },
  ],
  available_count: 2,
}

describe("parseResetCredits", () => {
  test("keeps only available credits, newest expiry last", () => {
    const credits = parseResetCredits(payload)
    expect(credits).toHaveLength(2)
    expect(credits[0]?.id).toBe("a")
    expect(credits[1]?.id).toBe("b")
  })

  test("parses ISO timestamps", () => {
    const [first] = parseResetCredits(payload)
    expect(first?.expiresAt).toBe(Date.parse("2026-11-30T19:55:01.428104Z"))
    expect(first?.grantedAt).toBe(Date.parse("2026-10-31T19:55:01.428104Z"))
  })

  test("accepts unix seconds", () => {
    const credits = parseResetCredits({ credits: [{ status: "available", expires_at: 1_800_000_000 }] })
    expect(credits[0]?.expiresAt).toBe(1_800_000_000_000)
  })

  test("ignores malformed payloads", () => {
    expect(parseResetCredits(null)).toEqual([])
    expect(parseResetCredits({})).toEqual([])
    expect(parseResetCredits({ credits: [{}] })).toEqual([])
  })
})

describe("expiry-prompt helpers", () => {
  const now = Date.parse("2026-11-11T12:00:00Z")

  test("selects the soonest-expiring credit inside the window", () => {
    const credits = [
      { id: "later", expiresAt: now + 20 * 60_000 },
      { id: "soon", expiresAt: now + 10 * 60_000 },
      { expiresAt: now + 1 * 60_000 },
      { id: "expired", expiresAt: now - 1 },
      { id: "far", expiresAt: now + 60 * 60_000 },
    ]
    expect(selectExpiringCredit(credits, now, 15)?.id).toBe("soon")
    expect(selectExpiringCredit(credits, now, 5)).toBeUndefined()
  })

})

describe("formatting", () => {
  test("formats ages", () => {
    expect(formatAge(42_000)).toBe("just now")
    expect(formatAge(5 * 60_000)).toBe("5m ago")
    expect(formatAge(3 * 3_600_000)).toBe("3h ago")
    expect(formatAge(4 * 86_400_000)).toBe("4d ago")
  })

  test("puts the time before the date", () => {
    const value = formatExpiry(Date.parse("2026-11-30T20:55:00Z"))
    expect(value).toMatch(/^\d{2}:\d{2} /)
    expect(value.indexOf(":")).toBeLessThan(value.search(/[A-Za-z]/))
  })

  test("formats time until expiry", () => {
    const now = Date.parse("2026-11-11T12:00:00Z")
    expect(formatTimeUntil(now + 5 * 60_000, now)).toBe("in 5m")
    expect(formatTimeUntil(now + 5 * 3_600_000, now)).toBe("in 5h")
    expect(formatTimeUntil(now + 2 * 86_400_000 + 3 * 3_600_000, now)).toBe("in 2d 3h")
    expect(formatTimeUntil(now + 19 * 86_400_000 + 3 * 3_600_000, now)).toBe("in 19d")
    expect(formatTimeUntil(now - 1, now)).toBe("expired")
  })
})

describe("formatDetails", () => {
  test("lists each credit with its expiry", () => {
    const state: ResetState = {
      credits: parseResetCredits(payload),
      fetchedAt: Date.parse("2026-11-11T12:00:00Z") - 65_000,
      missing: false,
      loading: false,
    }
    const details = formatDetails(state, Date.parse("2026-11-11T12:00:00Z"))
    expect(details).toContain("2 banked resets available.")
    expect(details).toContain("#1 Full reset (Weekly + 5 hr)")
    expect(details).toContain("granted")
    expect(details).toContain("Updated 1m ago.")
  })

  test("explains missing credentials", () => {
    expect(
      formatDetails({ credits: [], fetchedAt: 0, missing: true, loading: false }),
    ).toContain("Connect OpenAI in /connect")
  })
})
