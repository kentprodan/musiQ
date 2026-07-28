using CommunityToolkit.Mvvm.ComponentModel;

namespace MusiqWindows.ViewModels;

public enum TrackColumnKey
{
    Title,
    Time,
    Artist,
    Album,
    Year,
    Genre,
}

/// <summary>
/// One column of the Tracks table. Width and visibility are both
/// user-adjustable (drag a header edge to resize, right-click the header to
/// show/hide) and persisted across restarts by <c>LibraryPage</c>.
/// </summary>
public sealed partial class TrackColumn : ObservableObject
{
    public TrackColumnKey Key { get; }

    public string Header { get; }

    public double MinWidth { get; }

    /// Title can't be hidden — a row needs at least one identifying column
    /// visible, matching how Explorer/mp3tag both treat their Name column.
    public bool CanHide { get; }

    [ObservableProperty]
    private double _width;

    [ObservableProperty]
    private bool _isVisible = true;

    public TrackColumn(TrackColumnKey key, string header, double defaultWidth, double minWidth, bool canHide = true)
    {
        Key = key;
        Header = header;
        MinWidth = minWidth;
        CanHide = canHide;
        _width = defaultWidth;
    }

    public static string ValueFor(TrackItem track, TrackColumnKey key) => key switch
    {
        TrackColumnKey.Title => track.Title,
        TrackColumnKey.Time => track.Duration,
        TrackColumnKey.Artist => track.Artist,
        TrackColumnKey.Album => track.Album,
        TrackColumnKey.Year => track.Year,
        TrackColumnKey.Genre => track.Genre,
        _ => string.Empty,
    };

    public static TrackSortField ToSortField(TrackColumnKey key) => key switch
    {
        TrackColumnKey.Artist => TrackSortField.Artist,
        TrackColumnKey.Album => TrackSortField.Album,
        TrackColumnKey.Time => TrackSortField.Duration,
        TrackColumnKey.Year => TrackSortField.Year,
        TrackColumnKey.Genre => TrackSortField.Genre,
        _ => TrackSortField.Title,
    };
}
