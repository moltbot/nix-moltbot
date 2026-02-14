#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const configPath = process.env.OPENCLAW_CONFIG_PATH;
const srcRoot = process.env.OPENCLAW_SRC;

if (!configPath) {
  console.error("OPENCLAW_CONFIG_PATH is not set");
  process.exit(1);
}

if (!srcRoot) {
  console.error("OPENCLAW_SRC is not set");
  process.exit(1);
}

const legacyValidationPath = path.join(srcRoot, "dist", "config", "validation.js");
const distDir = path.join(srcRoot, "dist");

let validateConfigObject = null;

if (fs.existsSync(legacyValidationPath)) {
  const moduleUrl = pathToFileURL(legacyValidationPath).href;
  const legacyModule = await import(moduleUrl);
  validateConfigObject = legacyModule.validateConfigObject;
} else if (fs.existsSync(distDir)) {
  const candidates = fs.readdirSync(distDir)
    .filter((name) => name.startsWith("config-") && name.endsWith(".js"));

  for (const candidate of candidates) {
    const candidatePath = path.join(distDir, candidate);
    const contents = fs.readFileSync(candidatePath, "utf8");

    // Newer gateway bundles often only export validateConfigObjectWithPlugins (aliased),
    // while still containing an internal validateConfigObject function.
    if (!contents.includes("validateConfigObject") && !contents.includes("validateConfigObjectWithPlugins")) {
      continue;
    }

    if (contents.includes("./entry.js")) {
      continue;
    }

    const candidateModule = await import(pathToFileURL(candidatePath).href);

    // Prefer the plain validator when exported.
    if (typeof candidateModule.validateConfigObject === "function") {
      validateConfigObject = candidateModule.validateConfigObject;
      break;
    }

    // Fall back to the plugin-aware validator (what most bundles export today).
    if (typeof candidateModule.validateConfigObjectWithPlugins === "function") {
      validateConfigObject = candidateModule.validateConfigObjectWithPlugins;
      break;
    }

    // Handle minified alias exports.
    let match = contents.match(/validateConfigObject as ([A-Za-z0-9_$]+)/);
    if (match && typeof candidateModule[match[1]] === "function") {
      validateConfigObject = candidateModule[match[1]];
      break;
    }

    match = contents.match(/validateConfigObjectWithPlugins as ([A-Za-z0-9_$]+)/);
    if (match && typeof candidateModule[match[1]] === "function") {
      validateConfigObject = candidateModule[match[1]];
      break;
    }
  }
}

if (typeof validateConfigObject !== "function") {
  console.error(`Missing validation module: ${legacyValidationPath}`);
  process.exit(1);
}

const raw = fs.readFileSync(configPath, "utf8");
const parsed = JSON.parse(raw);

const result = validateConfigObject(parsed);
if (!result.ok) {
  console.error("OpenClaw config validation failed:");
  for (const issue of result.issues ?? []) {
    const pathLabel = issue.path ? ` ${issue.path}` : "";
    console.error(`- ${pathLabel}: ${issue.message}`);
  }
  process.exit(1);
}

console.log("openclaw config validation: ok");
