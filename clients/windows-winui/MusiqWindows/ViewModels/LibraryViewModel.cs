using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;

namespace MusiqWindows.ViewModels;

public partial class LibraryViewModel : ObservableObject
{
    [ObservableProperty]
    private bool _isScanning;

    [ObservableProperty]
    private string _statusMessage = "No folder scanned yet.";

    public ObservableCollection<TrackItem> Tracks { get; } = new();

    public LibraryViewModel()
    {
        _ = RefreshAsync();
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        var tracks = await LibraryService.Instance.ListTracksAsync();

        Tracks.Clear();
        foreach (var track in tracks)
        {
            Tracks.Add(TrackItem.From(track));
        }
    }

    public async Task ScanFolderAsync(string folderPath)
    {
        IsScanning = true;
        StatusMessage = $"Scanning {folderPath}…";

        try
        {
            var count = await LibraryService.Instance.ScanFolderAsync(folderPath);
            StatusMessage = $"Scanned {count} track(s) from {folderPath}.";
            await RefreshAsync();
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Scan failed: {ex.Message}";
        }
        finally
        {
            IsScanning = false;
        }
    }

    /// Plays `track` and queues the rest of the currently displayed list
    /// after it, so Next/Previous on the Now Playing page have something to
    /// move through.
    [RelayCommand]
    private async Task PlayTrackAsync(TrackItem track)
    {
        try
        {
            var startIndex = Tracks.IndexOf(track);
            await LibraryService.Instance.PlayQueueAsync(Tracks, startIndex);
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Playback failed: {ex.Message}";
        }
    }

    /// Writes title/artist/album for a single track. Unlike the batch path,
    /// all three fields are always applied — the dialog pre-fills them with
    /// the track's current values, so an unedited field is a no-op write.
    public async Task SaveTagEditAsync(string trackId, string title, string artist, string album)
    {
        try
        {
            await LibraryService.Instance.UpdateTagsAsync(new[] { trackId }, title, artist, album);
            await RefreshAsync();
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Tag update failed: {ex.Message}";
        }
    }

    /// Batch-writes artist/album (never title, since it's almost always
    /// per-track) across `trackIds`. A blank field means "leave untouched"
    /// here, not "clear" — batch-clearing isn't exposed by this dialog.
    public async Task SaveBatchTagEditAsync(IReadOnlyList<string> trackIds, string artist, string album)
    {
        string? artistUpdate = string.IsNullOrEmpty(artist) ? null : artist;
        string? albumUpdate = string.IsNullOrEmpty(album) ? null : album;

        if (artistUpdate is null && albumUpdate is null)
        {
            StatusMessage = "Nothing to update — fill in Artist and/or Album.";
            return;
        }

        try
        {
            var count = await LibraryService.Instance.UpdateTagsAsync(trackIds, null, artistUpdate, albumUpdate);
            StatusMessage = $"Updated tags on {count} track(s).";
            await RefreshAsync();
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Batch tag update failed: {ex.Message}";
        }
    }
}
