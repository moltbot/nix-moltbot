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

const validationPath = path.join(srcRoot, "dist", "config", "validation.js");
if (!fs.existsSync(validationPath)) {
  console.error(`Missing validation module: ${validationPath}`);
  process.exit(1);
}

const raw = fs.readFileSync(configPath, "utf8");
const parsed = JSON.parse(raw);
const moduleUrl = pathToFileURL(validationPath).href;
const { validateConfigObject } = await import(moduleUrl);

const result = validateConfigObject(parsed);
if (!result.ok) {
  console.error("Openclaw config validation failed:");
  for (const issue of result.issues ?? []) {
    const pathLabel = issue.path ? ` ${issue.path}` : "";
    console.error(`- ${pathLabel}: ${issue.message}`);
  }
  process.exit(1);
}

console.log("openclaw config validation: ok");
