import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

describe("Vercel client-side routes", () => {
  it("rewrites direct page requests to the React app entry point", () => {
    const config = JSON.parse(readFileSync("vercel.json", "utf8")) as {
      rewrites?: Array<{ source: string; destination: string }>;
    };

    expect(config.rewrites).toContainEqual({
      source: "/(.*)",
      destination: "/index.html",
    });
  });
});