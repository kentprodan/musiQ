using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;

namespace MusiqWindows.ViewModels;

/// <summary>
/// Reflects <see cref="LibraryService"/>'s single <c>Player</c> handle —
/// there is one playback state for the whole app, so this ViewModel just
/// mirrors it rather than owning any of its own.
/// </summary>
public partial class NowPlayingViewModel : ObservableObject
{
    [ObservableProperty]
    private string _trackTitle = "Nothing is playing";

    [ObservableProperty]
    private string _trackArtist = string.Empty;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(PlayPauseGlyph))]
    private bool _hasTrack;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(PlayPauseGlyph))]
    private bool _isPaused;

    /// Segoe Fluent Icons glyph (Play E768 / Pause E769 per Microsoft's
    /// Segoe Fluent Icons reference) for the transport toggle button.
    public string PlayPauseGlyph => !HasTrack || IsPaused ? "" : "";

    public NowPlayingViewModel()
    {
        LibraryService.Instance.CurrentTrackChanged += OnCurrentTrackChanged;
        OnCurrentTrackChanged();
    }

    /// Called from the page's Unloaded handler to avoid leaking this
    /// instance via the LibraryService singleton's event.
    public void Detach()
    {
        LibraryService.Instance.CurrentTrackChanged -= OnCurrentTrackChanged;
    }

    private void OnCurrentTrackChanged()
    {
        var track = LibraryService.Instance.CurrentTrack;
        HasTrack = track is not null;
        TrackTitle = track?.Title ?? "Nothing is playing";
        TrackArtist = track?.Artist ?? string.Empty;
        IsPaused = false;
    }

    [RelayCommand]
    private async Task PlayPauseAsync()
    {
        if (!HasTrack)
        {
            return;
        }

        if (IsPaused)
        {
            await LibraryService.Instance.ResumeAsync();
        }
        else
        {
            await LibraryService.Instance.PauseAsync();
        }

        IsPaused = !IsPaused;
    }

    [RelayCommand]
    private async Task StopAsync()
    {
        await LibraryService.Instance.StopAsync();
    }
}
