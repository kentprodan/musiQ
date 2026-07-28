using MusiqWindows.ViewModels;
using System.Linq;
using UniffiPlexAlbum = uniffi.musiq_uniffi.PlexAlbum;
using UniffiPlexArtist = uniffi.musiq_uniffi.PlexArtist;
using UniffiPlexClient = uniffi.musiq_uniffi.PlexClient;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the current Plex Media Server connection (if any). The server URL
/// and token are remembered in <see cref="CredentialStore"/> across app
/// restarts, but this service itself only ever holds the live connection.
///
/// Browsing mirrors Plex's own artist -&gt; album -&gt; track hierarchy (not a
/// flat dump of every track in a library, which doesn't scale past a small
/// collection). Playback is real streaming: each track's <c>StreamUrl</c> is
/// handed straight to <see cref="LibraryService"/>'s shared <c>Player</c>,
/// which fetches it on demand via HTTP range requests rather than
/// downloading the whole file first. Playing a track loads the whole
/// currently-shown album as a queue (Rust's <c>Player::set_queue</c> takes
/// plain path/URL strings, so a queue of stream URLs works exactly like a
/// queue of local files) so Next/Previous/shuffle/repeat work across an album.
/// </summary>
internal sealed class PlexService
{
    private static readonly Lazy<PlexService> LazyInstance = new(() => new PlexService());

    public static PlexService Instance => LazyInstance.Value;

    private UniffiPlexClient? _client;

    public bool IsConnected => _client is not null;

    /// Connects and verifies the token is accepted before returning —
    /// throws MusiqException if the server is unreachable or the token is bad.
    /// On success, remembers the server URL and token so the app can
    /// reconnect automatically next launch.
    public Task ConnectAsync(string baseUrl, string token) =>
        Task.Run(() =>
        {
            var client = new UniffiPlexClient(baseUrl, token);
            client.TestConnection();
            _client = client;
            CredentialStore.SavePlex(baseUrl, token);
        });

    /// Drops the live connection and forgets the saved server URL/token.
    public void Disconnect()
    {
        _client = null;
        CredentialStore.ClearPlex();
    }

    public Task<IReadOnlyList<UniffiPlexLibrary>> ListMusicLibrariesAsync() =>
        Task.Run(() => (IReadOnlyList<UniffiPlexLibrary>)RequireClient().ListMusicLibraries());

    public Task<IReadOnlyList<UniffiPlexArtist>> ListArtistsAsync(string sectionKey) =>
        Task.Run(() => (IReadOnlyList<UniffiPlexArtist>)RequireClient().ListArtists(sectionKey));

    public Task<IReadOnlyList<UniffiPlexAlbum>> ListAlbumsAsync(string artistRatingKey) =>
        Task.Run(() => (IReadOnlyList<UniffiPlexAlbum>)RequireClient().ListAlbums(artistRatingKey));

    /// Lists the tracks in the album `albumRatingKey`.
    public Task<IReadOnlyList<UniffiPlexTrack>> ListTracksAsync(string albumRatingKey) =>
        Task.Run(() => (IReadOnlyList<UniffiPlexTrack>)RequireClient().ListTracks(albumRatingKey));

    /// Plays `track`, queuing the rest of `queueTracks` (the currently-shown
    /// album's track listing, in its displayed order) around it so
    /// Next/Previous work across the whole album.
    public Task PlayTrackAsync(UniffiPlexTrack track, IReadOnlyList<UniffiPlexTrack> queueTracks)
    {
        var items = queueTracks.Select(t => TrackItem.FromPlex(t, t.StreamUrl)).ToList();
        var startIndex = items.FindIndex(t => t.Id == track.RatingKey);
        return LibraryService.Instance.PlayQueueAsync(items, Math.Max(startIndex, 0));
    }

    private UniffiPlexClient RequireClient() =>
        _client ?? throw new InvalidOperationException("Not connected to a Plex server yet.");
}
