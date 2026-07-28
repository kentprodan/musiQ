using Windows.Security.Credentials;

namespace MusiqWindows.Services;

/// <summary>
/// Remembers the last Plex/Navidrome connection in Windows' per-user
/// Credential Locker (<see cref="PasswordVault"/>) so the user isn't
/// re-typing a server URL and token/password on every launch. Values never
/// touch disk in our own code — the vault handles storage and encryption.
/// </summary>
internal static class CredentialStore
{
    private const string PlexResource = "musiQ.Plex";
    private const string NavidromeResource = "musiQ.Navidrome";

    /// A control character that can't appear in a URL or username, used to
    /// pack Navidrome's base URL and username into the vault's single
    /// UserName field (the vault only stores resource/username/password).
    private const char FieldSeparator = '\u0001';

    public static void SavePlex(string baseUrl, string token) =>
        Save(PlexResource, baseUrl, token);

    public static (string BaseUrl, string Token)? LoadPlex()
    {
        var entry = LoadFirst(PlexResource);
        if (entry is null)
        {
            return null;
        }

        return (entry.Value.UserName, entry.Value.Password);
    }

    public static void ClearPlex() => Clear(PlexResource);

    public static void SaveNavidrome(string baseUrl, string username, string password) =>
        Save(NavidromeResource, $"{baseUrl}{FieldSeparator}{username}", password);

    public static (string BaseUrl, string Username, string Password)? LoadNavidrome()
    {
        var entry = LoadFirst(NavidromeResource);
        if (entry is null)
        {
            return null;
        }

        var parts = entry.Value.UserName.Split(FieldSeparator, 2);
        return parts.Length == 2 ? (parts[0], parts[1], entry.Value.Password) : null;
    }

    public static void ClearNavidrome() => Clear(NavidromeResource);

    /// A resource/username pair can only be stored once — `Add` throws if an
    /// entry already exists, so a fresh connection always replaces the old one.
    private static void Save(string resource, string userName, string password)
    {
        Clear(resource);
        new PasswordVault().Add(new PasswordCredential(resource, userName, password));
    }

    private static (string UserName, string Password)? LoadFirst(string resource)
    {
        var vault = new PasswordVault();
        IReadOnlyList<PasswordCredential> credentials;
        try
        {
            // FindAllByResource throws (rather than returning empty) when
            // nothing's stored yet for this resource.
            credentials = vault.FindAllByResource(resource);
        }
        catch (Exception)
        {
            return null;
        }

        if (credentials.Count == 0)
        {
            return null;
        }

        var credential = credentials[0];
        credential.RetrievePassword();
        return (credential.UserName, credential.Password);
    }

    private static void Clear(string resource)
    {
        var vault = new PasswordVault();
        try
        {
            foreach (var credential in vault.FindAllByResource(resource))
            {
                vault.Remove(credential);
            }
        }
        catch (Exception)
        {
            // Nothing stored yet -- nothing to clear.
        }
    }
}
