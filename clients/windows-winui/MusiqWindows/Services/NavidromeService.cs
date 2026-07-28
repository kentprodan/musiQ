using MusiqWindows.ViewModels;
using System.Linq;
using uniffi.musiq_uniffi;
using UniffiNavidromeAlbum = uniffi.musiq_uniffi.NavidromeAlbum;
using UniffiNavidromeArtist = uniffi.musiq_uniffi.NavidromeArtist;
using UniffiNavidromeClient = uniffi.musiq_uniffi.NavidromeClient;
using UniffiNavidromeFolder = uniffi.musiq_uniffi.NavidromeFolder;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the current Navidrome/Subsonic-API server connection (if any).
/// Mirrors <see cref="PlexService"/>: real streaming via each song's
/// <c>StreamUrl</c> (`format=raw`, fetched on demand), playing a song queues
/// the rest of the currently-shown album/list around it, and the connection
/// (URL/username/password) is remembered in <see cref="CredentialStore"/>
/// across app restarts.
/// </summary>
internal sealed class NavidromeService
{
    private static readonly Lazy<NavidromeService> LazyInstance = new(() => new NavidromeService());

    public static NavidromeService Instance => LazyInstance.Value;

    private UniffiNavidromeClient? _client;

    public bool IsConnected => _client is not null;

    /// Connects and pings the server before returning — throws
    /// MusiqException if it's unreachable or the credentials are rejected.
    /// On success, remembers the server URL/username/password so the app can
    /// reconnect automatically next launch.
    public Task ConnectAsync(string baseUrl, string username, string password) =>
        Task.Run(() =>
        {
            var client = new UniffiNavidromeClient(baseUrl, username, password);
            client.TestConnection();
            _client = client;
            CredentialStore.SaveNavidrome(baseUrl, username, password);
        });

    /// Drops the live connection and forgets the saved server details.
    public void Disconnect()
    {
        _client = null;
        CredentialStore.ClearNavidrome();
    }

    /// Restores a previous connection from <see cref="CredentialStore"/> —
    /// called once at app startup so a server that was already connected
    /// shows up as available right away instead of only after a manual
    /// visit to Settings > Library sources. Best-effort: if the server is
    /// now unreachable or the credentials were rejected, this just leaves
    /// the service disconnected, same as if it had never been called.
    public async Task TryAutoConnectAsync()
    {
        if (CredentialStore.LoadNavidrome() is not (string baseUrl, string username, string password))
        {
            return;
        }

        try
        {
            await ConnectAsync(baseUrl, username, password);
        }
        catch (MusiqException)
        {
        }
    }

    public Task<IReadOnlyList<UniffiNavidromeFolder>> ListMusicFoldersAsync() =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeFolder>)RequireClient().ListMusicFolders());

    public Task<IReadOnlyList<UniffiNavidromeArtist>> ListArtistsAsync(string folderId) =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeArtist>)RequireClient().ListArtists(folderId));

    public Task<IReadOnlyList<UniffiNavidromeAlbum>> ListAlbumsAsync(string artistId) =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeAlbum>)RequireClient().ListAlbums(artistId));

    public Task<IReadOnlyList<UniffiNavidromeSong>> ListSongsAsync(string albumId) =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeSong>)RequireClient().ListSongs(albumId));

    /// Plays `song`, queuing the rest of `queueSongs` (the currently-shown
    /// album's song list, in its displayed order) around it so Next/Previous
    /// work across the whole album.
    public Task PlayTrackAsync(UniffiNavidromeSong song, IReadOnlyList<UniffiNavidromeSong> queueSongs)
    {
        var items = queueSongs.Select(TrackItem.FromNavidrome).ToList();
        var startIndex = items.FindIndex(t => t.Id == song.Id);
        return LibraryService.Instance.PlayQueueAsync(items, Math.Max(startIndex, 0));
    }

    private UniffiNavidromeClient RequireClient() =>
        _client ?? throw new InvalidOperationException("Not connected to a Navidrome server yet.");
}
