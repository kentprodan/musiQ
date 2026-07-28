using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using UniffiRepeatMode = uniffi.musiq_uniffi.RepeatMode;

namespace MusiqWindows.ViewModels;

/// Mirrors the FFI's internal `RepeatMode` enum with a public one, since a
/// public ViewModel property can't expose an `internal` generated type.
public enum RepeatModeOption
{
    Off,
    All,
    One,
}

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

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(ShuffleOpacity))]
    private bool _isShuffled;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(RepeatGlyph))]
    [NotifyPropertyChangedFor(nameof(RepeatOpacity))]
    private RepeatModeOption _repeatMode = RepeatModeOption.Off;

    /// Segoe Fluent Icons glyphs (Play E768 / Pause E769) per Microsoft's
    /// Segoe Fluent Icons reference, for the transport toggle button.
    public string PlayPauseGlyph => !HasTrack || IsPaused ? "" : "";

    public double ShuffleOpacity => IsShuffled ? 1.0 : 0.5;

    /// Repeat E8EE / Repeat-one E8ED, also per the Segoe Fluent Icons reference.
    public string RepeatGlyph => RepeatMode == RepeatModeOption.One ? "" : "";

    public double RepeatOpacity => RepeatMode == RepeatModeOption.Off ? 0.5 : 1.0;

    public NowPlayingViewModel()
    {
        LibraryService.Instance.CurrentTrackChanged += OnCurrentTrackChanged;
        OnCurrentTrackChanged();
        _ = RefreshQueueControlsAsync();
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

    private async Task RefreshQueueControlsAsync()
    {
        IsShuffled = await LibraryService.Instance.IsShuffledAsync();
        RepeatMode = ToOption(await LibraryService.Instance.GetRepeatModeAsync());
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

    [RelayCommand]
    private async Task NextAsync()
    {
        await LibraryService.Instance.NextAsync();
        IsPaused = false;
    }

    [RelayCommand]
    private async Task PreviousAsync()
    {
        await LibraryService.Instance.PreviousAsync();
        IsPaused = false;
    }

    [RelayCommand]
    private async Task ToggleShuffleAsync()
    {
        await LibraryService.Instance.ToggleShuffleAsync();
        IsShuffled = await LibraryService.Instance.IsShuffledAsync();
    }

    [RelayCommand]
    private async Task CycleRepeatModeAsync()
    {
        var next = RepeatMode switch
        {
            RepeatModeOption.Off => RepeatModeOption.All,
            RepeatModeOption.All => RepeatModeOption.One,
            _ => RepeatModeOption.Off,
        };
        await LibraryService.Instance.SetRepeatModeAsync(ToUniffi(next));
        RepeatMode = next;
    }

    private static RepeatModeOption ToOption(UniffiRepeatMode mode) => mode switch
    {
        UniffiRepeatMode.Off => RepeatModeOption.Off,
        UniffiRepeatMode.All => RepeatModeOption.All,
        UniffiRepeatMode.One => RepeatModeOption.One,
        _ => RepeatModeOption.Off,
    };

    private static UniffiRepeatMode ToUniffi(RepeatModeOption option) => option switch
    {
        RepeatModeOption.Off => UniffiRepeatMode.Off,
        RepeatModeOption.All => UniffiRepeatMode.All,
        RepeatModeOption.One => UniffiRepeatMode.One,
        _ => UniffiRepeatMode.Off,
    };
}
