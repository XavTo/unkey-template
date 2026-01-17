import { generateAPIKey } from "prefixed-api-key";

const key = await generateAPIKey({ keyPrefix: "unkey" });

console.log(key);
