using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;

namespace MusiqWindows.ViewModels;

public enum TrackSortField
{
    Title,
    Artist,
    Album,
    Duration,
    Year,
    Genre,
}

public partial class LibraryViewModel : ObservableObject
{
    [ObservableProperty]
    private bool _isScanning;

    [ObservableProperty]
    private string _statusMessage = "No folder scanned yet.";

    [ObservableProperty]
    private string _filterText = string.Empty;

    [ObservableProperty]
    private TrackSortField _sortField = TrackSortField.Title;

    [ObservableProperty]
    private bool _sortDescending;

    // Backs `Tracks` (the filtered/sorted view the ListView and queueing both
    // read from) — kept separate so re-applying the filter/sort doesn't need
    // a round-trip to LibraryService.
    private List<TrackItem> _allTracks = new();

    public ObservableCollection<TrackItem> Tracks { get; } = new();

    public LibraryViewModel()
    {
        _ = RefreshAsync();
    }

    partial void OnFilterTextChanged(string value) => ApplyFilterAndSort();

    partial void OnSortFieldChanged(TrackSortField value) => ApplyFilterAndSort();

    partial void OnSortDescendingChanged(bool value) => ApplyFilterAndSort();

    [RelayCommand]
    private async Task RefreshAsync()
    {
        var tracks = await LibraryService.Instance.ListTracksAsync();
        var items = tracks.Select(TrackItem.From).ToList();

        // Cache-first on the Rust side (a no-op file-exists check after the
        // first extraction), so fetching every track's art in parallel here
        // is cheap even for a large library.
        var artByTrackId = (await Task.WhenAll(items.Select(async item =>
        {
            var path = await LibraryService.Instance.GetTrackArtPathAsync(item.Id);
            return (item.Id, ArtUrl: path is null ? null : new Uri(path).AbsoluteUri);
        }))).ToDictionary(pair => pair.Id, pair => pair.ArtUrl);

        _allTracks = items
            .Select(item => item with { ArtUrl = artByTrackId.GetValueOrDefault(item.Id) })
            .ToList();
        ApplyFilterAndSort();
    }

    private void ApplyFilterAndSort()
    {
        IEnumerable<TrackItem> query = _allTracks;

        if (!string.IsNullOrWhiteSpace(FilterText))
        {
            query = query.Where(t =>
                t.Title.Contains(FilterText, StringComparison.OrdinalIgnoreCase) ||
                t.Artist.Contains(FilterText, StringComparison.OrdinalIgnoreCase) ||
                t.Album.Contains(FilterText, StringComparison.OrdinalIgnoreCase));
        }

        query = SortField switch
        {
            TrackSortField.Artist => SortDescending ? query.OrderByDescending(t => t.Artist) : query.OrderBy(t => t.Artist),
            TrackSortField.Album => SortDescending ? query.OrderByDescending(t => t.Album) : query.OrderBy(t => t.Album),
            TrackSortField.Duration => SortDescending ? query.OrderByDescending(t => t.DurationSecs ?? 0) : query.OrderBy(t => t.DurationSecs ?? 0),
            TrackSortField.Year => SortDescending ? query.OrderByDescending(t => t.Year) : query.OrderBy(t => t.Year),
            TrackSortField.Genre => SortDescending ? query.OrderByDescending(t => t.Genre) : query.OrderBy(t => t.Genre),
            _ => SortDescending ? query.OrderByDescending(t => t.Title) : query.OrderBy(t => t.Title),
        };

        Tracks.Clear();
        foreach (var track in query)
        {
            Tracks.Add(track);
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

    /// Moves every track in `trackIds` to `baseFolder` joined with `pattern`.
    public async Task SaveRenameAsync(IReadOnlyList<string> trackIds, string baseFolder, string pattern)
    {
        try
        {
            var count = await LibraryService.Instance.RenameTracksAsync(trackIds, baseFolder, pattern);
            StatusMessage = $"Renamed {count} track(s) into {baseFolder}.";
            await RefreshAsync();
        }
        catch (MusiqException ex)
        {
            StatusMessage = $"Rename failed: {ex.Message}";
        }
    }
}
