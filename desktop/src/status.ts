import { stringsFor, type Strings } from "./strings";

// Shared mapping of a check_server / server-command failure to a user-facing
// status. check_server raises ServerError::InvalidUrl (Display "Invalid server
// URL: …") for malformed URLs. Keep those diagnostic prefixes stable while
// showing translated messages, including storage failures, to the user.
export function serverErrorMessage(e: unknown, S: Strings["connect"] = stringsFor("en").connect): string {
  const error = String(e);
  if (error.startsWith("Invalid server URL:")) return S.invalidUrl;
  if (error.startsWith("Keychain error:")) return S.storageError;
  return S.unreachable;
}
