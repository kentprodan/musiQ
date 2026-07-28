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
/// Playback is real streaming: <c>track.StreamUrl</c> is handed straight to
/// <see cref="LibraryService"/>'s shared <c>Player</c>, which fetches it on
/// demand via HTTP range requests rather than downloading the whole file first.
/// </summary>
internal sealed class PlexService
{
    private static readonly Lazy<PlexService> LazyInstance = new(() => new PlexService());

    public static PlexService Instance => LazyInstance.Value;

    private UniffiPlexClient? _client;

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

    public Task PlayTrackAsync(UniffiPlexTrack track)
    {
        var displayItem = TrackItem.FromPlex(track, track.StreamUrl);
        return LibraryService.Instance.PlayAdHocAsync(track.StreamUrl, displayItem);
    }

    private UniffiPlexClient RequireClient() =>
        _client ?? throw new InvalidOperationException("Not connected to a Plex server yet.");
}
