using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;
using UniffiTrack = uniffi.musiq_uniffi.Track;

namespace MusiqWindows.ViewModels;

/// <summary>
/// Flat, pre-formatted view of a track for display, whether it came from the
/// local library (<see cref="UniffiTrack"/>) or a Plex server
/// (<see cref="UniffiPlexTrack"/>). Exists so XAML never has to deal with
/// nullable fields or raw seconds directly.
///
/// <c>Title</c>/<c>Artist</c>/<c>Album</c> are display strings with
/// placeholder fallbacks baked in ("Unknown Artist" etc) — the tag-edit
/// dialogs must pre-fill from <c>RawTitle</c>/<c>RawArtist</c>/<c>RawAlbum</c>
/// instead, or they'd write those placeholders into the file as real tags.
/// </summary>
public sealed record TrackItem(
    string Id,
    string Title,
    string Artist,
    string Album,
    string Duration,
    string Path,
    string? RawTitle,
    string? RawArtist,
    string? RawAlbum)
{
    internal static TrackItem From(UniffiTrack track)
    {
        var title = string.IsNullOrWhiteSpace(track.Title)
            ? System.IO.Path.GetFileNameWithoutExtension(track.Path)
            : track.Title!;

        return new TrackItem(
            Id: track.Id,
            Title: title,
            Artist: track.Artist ?? "Unknown Artist",
            Album: track.Album ?? "Unknown Album",
            Duration: FormatDuration(track.DurationSecs),
            Path: track.Path,
            RawTitle: track.Title,
            RawArtist: track.Artist,
            RawAlbum: track.Album);
    }

    /// <param name="localPath">Where the track was (or will be) downloaded to —
    /// Plex playback works by downloading to a temp file and playing that,
    /// same as any other local file.</param>
    internal static TrackItem FromPlex(UniffiPlexTrack track, string localPath)
    {
        return new TrackItem(
            Id: track.RatingKey,
            Title: string.IsNullOrWhiteSpace(track.Title) ? "Untitled" : track.Title,
            Artist: track.Artist ?? "Unknown Artist",
            Album: track.Album ?? "Unknown Album",
            Duration: FormatDuration(track.DurationSecs),
            Path: localPath,
            RawTitle: track.Title,
            RawArtist: track.Artist,
            RawAlbum: track.Album);
    }

    private static string FormatDuration(uint? secs) =>
        secs is uint value ? $"{value / 60}:{value % 60:D2}" : "--:--";
}
