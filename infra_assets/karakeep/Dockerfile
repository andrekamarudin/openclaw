ARG KARAKEEP_VERSION=release
FROM ghcr.io/karakeep-app/karakeep:${KARAKEEP_VERSION}

RUN node <<'EOF'
const fs = require("fs");
const path = require("path");

const chunksDir = "/app/apps/web/.next/server/chunks";
const oldSnippet = "this.config.useMaxCompletionTokens?{max_completion_tokens:this.config.maxOutputTokens}:{max_tokens:this.config.maxOutputTokens}";
const newSnippet = "{max_completion_tokens:this.config.maxOutputTokens}";

const patchedFiles = [];
let patchedOccurrences = 0;

for (const entry of fs.readdirSync(chunksDir, { withFileTypes: true })) {
  if (!entry.isFile() || !entry.name.endsWith(".js")) {
    continue;
  }

  const filePath = path.join(chunksDir, entry.name);
  const text = fs.readFileSync(filePath, "utf8");

  if (!text.includes(oldSnippet)) {
    continue;
  }

  const occurrences = text.split(oldSnippet).length - 1;
  fs.writeFileSync(filePath, text.split(oldSnippet).join(newSnippet));
  patchedFiles.push(filePath);
  patchedOccurrences += occurrences;
}

if (patchedFiles.length !== 1) {
  throw new Error(`Expected to patch exactly 1 chunk, patched ${patchedFiles.length}: ${patchedFiles.join(", ")}`);
}

if (patchedOccurrences < 1) {
  throw new Error("Expected to patch at least one legacy token branch");
}

console.log(`Patched ${patchedFiles[0]} (${patchedOccurrences} occurrences)`);
EOF
