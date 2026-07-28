using UniffiTrack = uniffi.musiq_uniffi.Track;

namespace MusiqWindows.ViewModels;

/// <summary>
/// Flat, pre-formatted view of a <see cref="UniffiTrack"/> for display in
/// <c>LibraryPage</c>'s <c>ListView</c>. Exists so XAML never has to deal
/// with the FFI record's nullable fields or raw seconds directly.
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

        var duration = track.DurationSecs is uint secs
            ? $"{secs / 60}:{secs % 60:D2}"
            : "--:--";

        return new TrackItem(
            Id: track.Id,
            Title: title,
            Artist: track.Artist ?? "Unknown Artist",
            Album: track.Album ?? "Unknown Album",
            Duration: duration,
            Path: track.Path,
            RawTitle: track.Title,
            RawArtist: track.Artist,
            RawAlbum: track.Album);
    }
}
