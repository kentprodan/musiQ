using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Dispatching;
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

/// One row of the "up next" list — the queue in its current play order,
/// with the currently-loaded track flagged so the UI can highlight it.
public sealed record QueueItemDisplay(TrackItem Track, bool IsCurrent)
{
    public double TitleOpacity => IsCurrent ? 1.0 : 0.7;
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
    [NotifyPropertyChangedFor(nameof(CanSeek))]
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

    /// Total duration of the current track, in seconds — the seek bar's
    /// range. 0 (and the bar disabled) when unknown or nothing is loaded.
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanSeek))]
    [NotifyPropertyChangedFor(nameof(DurationText))]
    private double _durationSecs;

    public bool CanSeek => HasTrack && DurationSecs > 0;

    public string DurationText => DurationSecs > 0 ? FormatSeconds(DurationSecs) : "--:--";


    public ObservableCollection<QueueItemDisplay> UpNext { get; } = new();

    /// Segoe Fluent Icons glyphs (Play E768 / Pause E769) per Microsoft's
    /// Segoe Fluent Icons reference, for the transport toggle button.
    public string PlayPauseGlyph => !HasTrack || IsPaused ? "\uE768" : "\uE769";

    public double ShuffleOpacity => IsShuffled ? 1.0 : 0.5;

    /// Repeat E8EE / Repeat-one E8ED, also per the Segoe Fluent Icons reference.
    public string RepeatGlyph => RepeatMode == RepeatModeOption.One ? "\uE8ED" : "\uE8EE";

    public double RepeatOpacity => RepeatMode == RepeatModeOption.Off ? 0.5 : 1.0;

    /// Fired roughly twice a second with the current playback position (in
    /// seconds) while a track is loaded. The page owns the seek bar's actual
    /// `Value` so it can suppress updates while the user is dragging the
    /// thumb — that state lives in the page, not here.
    public event Action<double>? PositionChanged;

    private readonly DispatcherQueueTimer? _positionTimer;

    public NowPlayingViewModel()
    {
        LibraryService.Instance.CurrentTrackChanged += OnCurrentTrackChanged;
        OnCurrentTrackChanged();
        _ = RefreshQueueControlsAsync();

        var dispatcherQueue = DispatcherQueue.GetForCurrentThread();
        if (dispatcherQueue is not null)
        {
            _positionTimer = dispatcherQueue.CreateTimer();
            _positionTimer.Interval = TimeSpan.FromMilliseconds(500);
            _positionTimer.IsRepeating = true;
            _positionTimer.Tick += async (_, _) => await PollPositionAsync();
            _positionTimer.Start();
        }
    }

    /// Called from the page's Unloaded handler to avoid leaking this
    /// instance via the LibraryService singleton's event, and to stop the
    /// position-polling timer once the page isn't visible.
    public void Detach()
    {
        LibraryService.Instance.CurrentTrackChanged -= OnCurrentTrackChanged;
        _positionTimer?.Stop();
    }

    private void OnCurrentTrackChanged()
    {
        var track = LibraryService.Instance.CurrentTrack;
        HasTrack = track is not null;
        TrackTitle = track?.Title ?? "Nothing is playing";
        TrackArtist = track?.Artist ?? string.Empty;
        DurationSecs = track?.DurationSecs ?? 0;
        IsPaused = false;
        _ = RefreshUpNextAsync();
    }

    private async Task RefreshUpNextAsync()
    {
        var queue = await LibraryService.Instance.GetQueueInPlayOrderAsync();
        var currentId = LibraryService.Instance.CurrentTrack?.Id;

        UpNext.Clear();
        foreach (var track in queue)
        {
            UpNext.Add(new QueueItemDisplay(track, track.Id == currentId));
        }
    }

    private async Task PollPositionAsync()
    {
        if (!HasTrack)
        {
            return;
        }

        var position = await LibraryService.Instance.GetPositionSecondsAsync();
        PositionChanged?.Invoke(position);
    }

    public Task SeekAsync(double seconds) =>
        LibraryService.Instance.SeekAsync(seconds);

    public async Task PlayQueueItemAsync(TrackItem track)
    {
        await LibraryService.Instance.PlayQueueItemAsync(track);
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

    internal static string FormatSeconds(double totalSeconds)
    {
        var total = (int)totalSeconds;
        return $"{total / 60}:{total % 60:D2}";
    }
}
