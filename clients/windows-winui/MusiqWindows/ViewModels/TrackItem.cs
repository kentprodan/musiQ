using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;
using UniffiTrack = uniffi.musiq_uniffi.Track;

namespace MusiqWindows.ViewModels;

/// <summary>
/// Flat, pre-formatted view of a track for display, whether it came from the
/// local library (<see cref="UniffiTrack"/>) or a streaming source
/// (<see cref="UniffiPlexTrack"/>, <see cref="UniffiNavidromeSong"/>). Exists
/// so XAML never has to deal with nullable fields or raw seconds directly.
///
/// <c>Path</c> is whatever <c>Player.Play</c> accepts — a local filesystem
/// path for library tracks, or an <c>http(s)://</c> stream URL for Plex/
/// Navidrome (fetched on demand via HTTP range requests, not downloaded first).
///
/// <c>Title</c>/<c>Artist</c>/<c>Album</c> are display strings with
/// placeholder fallbacks baked in ("Unknown Artist" etc) — the tag-edit
/// dialogs must pre-fill from <c>RawTitle</c>/<c>RawArtist</c>/<c>RawAlbum</c>
/// instead, or they'd write those placeholders into the file as real tags.
///
/// <c>DurationSecs</c> is the numeric duration (for the Now Playing seek
/// bar's range) alongside <c>Duration</c>, the pre-formatted "m:ss" string.
/// </summary>
public sealed record TrackItem(
    string Id,
    string Title,
    string Artist,
    string Album,
    string Duration,
    uint? DurationSecs,
    string Path,
    string? RawTitle,
    string? RawArtist,
    string? RawAlbum,
    string Year,
    string Genre)
{
    /// Embedded cover art, as a `file:///`-style absolute URI string that
    /// XAML's `Image.Source` converter can bind to directly. `null` for
    /// Plex/Navidrome tracks (their album art is shown at the album level,
    /// not per-track) or local tracks with no embedded picture.
    public string? ArtUrl { get; init; }

    /// `Image.Source`'s implicit string->ImageSource conversion
    /// (`XamlBindingHelper.ConvertValue`) throws `ArgumentException` for a
    /// null value instead of producing an empty source, which crashed the
    /// app on every track with no embedded art. Building the `ImageSource`
    /// explicitly here sidesteps that conversion entirely.
    public ImageSource? ArtImageSource => ArtUrl is null ? null : new BitmapImage(new Uri(ArtUrl));


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
            DurationSecs: track.DurationSecs,
            Path: track.Path,
            RawTitle: track.Title,
            RawArtist: track.Artist,
            RawAlbum: track.Album,
            Year: track.Year?.ToString() ?? string.Empty,
            Genre: track.Genre ?? string.Empty);
    }

    // Plex/Navidrome don't surface year/genre in what they return today —
    // browsing them is organized by artist/album, not a flat tag dump like
    // the local library's scan.
    internal static TrackItem FromPlex(UniffiPlexTrack track, string streamUrl)
    {
        return new TrackItem(
            Id: track.RatingKey,
            Title: string.IsNullOrWhiteSpace(track.Title) ? "Untitled" : track.Title,
            Artist: track.Artist ?? "Unknown Artist",
            Album: track.Album ?? "Unknown Album",
            Duration: FormatDuration(track.DurationSecs),
            DurationSecs: track.DurationSecs,
            Path: streamUrl,
            RawTitle: track.Title,
            RawArtist: track.Artist,
            RawAlbum: track.Album,
            Year: string.Empty,
            Genre: string.Empty);
    }

    internal static TrackItem FromNavidrome(UniffiNavidromeSong song)
    {
        return new TrackItem(
            Id: song.Id,
            Title: string.IsNullOrWhiteSpace(song.Title) ? "Untitled" : song.Title,
            Artist: song.Artist ?? "Unknown Artist",
            Album: song.Album ?? "Unknown Album",
            Duration: FormatDuration(song.DurationSecs),
            DurationSecs: song.DurationSecs,
            Path: song.StreamUrl,
            RawTitle: song.Title,
            RawArtist: song.Artist,
            RawAlbum: song.Album,
            Year: string.Empty,
            Genre: string.Empty);
    }

    private static string FormatDuration(uint? secs) =>
        secs is uint value ? $"{value / 60}:{value % 60:D2}" : "--:--";
}
