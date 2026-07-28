using MusiqWindows.ViewModels;
using UniffiPlexClient = uniffi.musiq_uniffi.PlexClient;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the current Plex Media Server connection (if any). Unlike
/// <see cref="LibraryService"/>, there's no persistent state to keep across
/// app restarts yet — connecting is a per-session action.
///
/// Playback works by downloading a track to a temp file and handing that to
/// <see cref="LibraryService"/>'s existing <c>Player</c> — there's no true
/// streaming (progressive download / range requests) yet, so Play doesn't
/// start audio until the whole file has downloaded.
/// </summary>
internal sealed class PlexService
{
    private static readonly Lazy<PlexService> LazyInstance = new(() => new PlexService());

    public static PlexService Instance => LazyInstance.Value;

    private UniffiPlexClient? _client;

    private readonly string _downloadDir = Path.Combine(
        Windows.Storage.ApplicationData.Current.TemporaryFolder.Path, "plex");

    public bool IsConnected => _client is not null;

    /// Connects and verifies the token is accepted before returning —
    /// throws MusiqException if the server is unreachable or the token is bad.
    public Task ConnectAsync(string baseUrl, string token) =>
        Task.Run(() =>
        {
            var client = new UniffiPlexClient(baseUrl, token);
            client.TestConnection();
            _client = client;
        });

    public Task<IReadOnlyList<UniffiPlexLibrary>> ListMusicLibrariesAsync() =>
        Task.Run(() => (IReadOnlyList<UniffiPlexLibrary>)RequireClient().ListMusicLibraries());

    public Task<IReadOnlyList<UniffiPlexTrack>> ListTracksAsync(string sectionKey) =>
        Task.Run(() => (IReadOnlyList<UniffiPlexTrack>)RequireClient().ListTracks(sectionKey));

    /// Downloads `track` (if not already cached from a previous play) and
    /// starts playing it through the shared player.
    public async Task PlayTrackAsync(UniffiPlexTrack track)
    {
        var client = RequireClient();
        var localPath = await Task.Run(() => client.DownloadTrack(track, _downloadDir));
        var displayItem = TrackItem.FromPlex(track, localPath);
        await LibraryService.Instance.PlayAdHocAsync(localPath, displayItem);
    }

    private UniffiPlexClient RequireClient() =>
        _client ?? throw new InvalidOperationException("Not connected to a Plex server yet.");
}
