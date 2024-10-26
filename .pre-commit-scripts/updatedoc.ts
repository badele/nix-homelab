#!/usr/bin/env -S deno run --allow-sys --allow-read --allow-env --allow-net --allow-run --allow-write

function replaceCode(tag: string, content: string, replace: string): string {
  const regex = new RegExp(`<!-- ${tag} -->.*/${tag} -->`, "sm");
  return content.replace(
    regex,
    `<!-- ${tag} -->\n\n\`\`\`text\n${replace}\`\`\`\n\n<!-- /${tag} -->`,
  );
}

///////////////////////////////////////////////////////////////////////////////
// Read README.md
///////////////////////////////////////////////////////////////////////////////

const doc = await Deno.readTextFile("README.md");

///////////////////////////////////////////////////////////////////////////////
// Execute commands
///////////////////////////////////////////////////////////////////////////////

// List commands
const cmdcommands = new Deno.Command("just", {});
let { stdout } = await cmdcommands.output();
const outputcommands = new TextDecoder().decode(stdout);

// List packages
const cmdpackages = new Deno.Command("just", { args: ["packages"] });
({ stdout } = await cmdpackages.output());
const outputpackages = new TextDecoder().decode(stdout);

///////////////////////////////////////////////////////////////////////////////
// Replace tags
///////////////////////////////////////////////////////////////////////////////

let result = replaceCode("COMMANDS", doc, outputcommands);
result = replaceCode("PACKAGES", result, outputpackages);

///////////////////////////////////////////////////////////////////////////////
// Update READLE.md
///////////////////////////////////////////////////////////////////////////////

await Deno.writeTextFile("README.md", result);
