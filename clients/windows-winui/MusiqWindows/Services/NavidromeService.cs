using MusiqWindows.ViewModels;
using UniffiNavidromeAlbum = uniffi.musiq_uniffi.NavidromeAlbum;
using UniffiNavidromeClient = uniffi.musiq_uniffi.NavidromeClient;
using UniffiNavidromeFolder = uniffi.musiq_uniffi.NavidromeFolder;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the current Navidrome/Subsonic-API server connection (if any).
/// Mirrors <see cref="PlexService"/>: real streaming via
/// <c>song.StreamUrl</c> (`format=raw`, fetched on demand), no download step.
/// </summary>
internal sealed class NavidromeService
{
    private static readonly Lazy<NavidromeService> LazyInstance = new(() => new NavidromeService());

    public static NavidromeService Instance => LazyInstance.Value;

    private UniffiNavidromeClient? _client;

    public bool IsConnected => _client is not null;

    /// Connects and pings the server before returning — throws
    /// MusiqException if it's unreachable or the credentials are rejected.
    public Task ConnectAsync(string baseUrl, string username, string password) =>
        Task.Run(() =>
        {
            var client = new UniffiNavidromeClient(baseUrl, username, password);
            client.TestConnection();
            _client = client;
        });

    public Task<IReadOnlyList<UniffiNavidromeFolder>> ListMusicFoldersAsync() =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeFolder>)RequireClient().ListMusicFolders());

    public Task<IReadOnlyList<UniffiNavidromeAlbum>> ListAlbumsAsync(string folderId) =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeAlbum>)RequireClient().ListAlbums(folderId));

    public Task<IReadOnlyList<UniffiNavidromeSong>> ListSongsAsync(string albumId) =>
        Task.Run(() => (IReadOnlyList<UniffiNavidromeSong>)RequireClient().ListSongs(albumId));

    public Task PlayTrackAsync(UniffiNavidromeSong song)
    {
        var displayItem = TrackItem.FromNavidrome(song);
        return LibraryService.Instance.PlayAdHocAsync(song.StreamUrl, displayItem);
    }

    private UniffiNavidromeClient RequireClient() =>
        _client ?? throw new InvalidOperationException("Not connected to a Navidrome server yet.");
}
