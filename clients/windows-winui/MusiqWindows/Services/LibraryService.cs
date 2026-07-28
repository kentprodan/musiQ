using Microsoft.UI.Dispatching;
using MusiqWindows.ViewModels;
using uniffi.musiq_uniffi;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the single <see cref="Library"/> and <see cref="Player"/> handles for
/// the app's lifetime and wraps every call to them in <see cref="Task.Run"/>,
/// since the underlying Rust core does synchronous SQLite/file/audio-device
/// I/O and must never block the UI thread.
/// </summary>
internal sealed class LibraryService
{
    private static readonly Lazy<LibraryService> LazyInstance = new(() => new LibraryService());

    public static LibraryService Instance => LazyInstance.Value;

    public string DatabasePath { get; }

    private readonly Library _library;
    private readonly Player _player;
    private readonly DispatcherQueueTimer? _pollTimer;

    /// The tracks passed to the most recent <see cref="PlayQueueAsync"/> call,
    /// in their original (unshuffled) order — indexed by <c>Player.QueuePosition()</c>.
    private List<TrackItem> _queueTracks = new();

    /// <summary>The currently loaded/playing track, or <c>null</c> once the
    /// queue is stopped or exhausted. Raised on the UI thread — every caller
    /// that triggers a change is either already on it, or (for auto-advance)
    /// the poll timer, which runs on the UI thread's DispatcherQueue.</summary>
    public TrackItem? CurrentTrack { get; private set; }

    public event Action? CurrentTrackChanged;

    private LibraryService()
    {
        var localFolder = Windows.Storage.ApplicationData.Current.LocalFolder.Path;
        DatabasePath = Path.Combine(localFolder, "musiq-library.sqlite3");
        _library = Library.Open(DatabasePath);
        _player = new Player();

        // rodio has no "playback finished" callback, so auto-advance to the
        // next queued track is driven by polling from the UI thread.
        var dispatcherQueue = DispatcherQueue.GetForCurrentThread();
        if (dispatcherQueue is not null)
        {
            _pollTimer = dispatcherQueue.CreateTimer();
            _pollTimer.Interval = TimeSpan.FromMilliseconds(500);
            _pollTimer.IsRepeating = true;
            _pollTimer.Tick += async (_, _) => await PollForTrackEndAsync();
            _pollTimer.Start();
        }
    }

    public Task<uint> ScanFolderAsync(string folderPath) =>
        Task.Run(() => _library.ScanFolder(folderPath));

    public Task<IReadOnlyList<Track>> ListTracksAsync() =>
        Task.Run(() => (IReadOnlyList<Track>)_library.ListTracks());

    public Task<IReadOnlyList<string>> ListScanRootsAsync() =>
        Task.Run(() => (IReadOnlyList<string>)_library.ListScanRoots());

    /// Replaces the queue with `tracks` and starts playing the one at `startIndex`.
    public async Task PlayQueueAsync(IReadOnlyList<TrackItem> tracks, int startIndex)
    {
        _queueTracks = tracks.ToList();
        var paths = _queueTracks.Select(t => t.Path).ToArray();
        await Task.Run(() => _player.SetQueue(paths, (uint)startIndex));
        RefreshCurrentTrackFromQueue();
    }

    public async Task NextAsync()
    {
        await Task.Run(() => _player.Next());
        RefreshCurrentTrackFromQueue();
    }

    public async Task PreviousAsync()
    {
        await Task.Run(() => _player.Previous());
        RefreshCurrentTrackFromQueue();
    }

    public Task PauseAsync() =>
        Task.Run(() => _player.Pause());

    public Task ResumeAsync() =>
        Task.Run(() => _player.Resume());

    public async Task StopAsync()
    {
        await Task.Run(() => _player.Stop());
        CurrentTrack = null;
        CurrentTrackChanged?.Invoke();
    }

    public Task<bool> IsPausedAsync() =>
        Task.Run(() => _player.IsPaused());

    public async Task ToggleShuffleAsync()
    {
        var next = !await Task.Run(() => _player.IsShuffled());
        await Task.Run(() => _player.SetShuffle(next));
    }

    public Task<bool> IsShuffledAsync() =>
        Task.Run(() => _player.IsShuffled());

    public Task SetRepeatModeAsync(RepeatMode mode) =>
        Task.Run(() => _player.SetRepeatMode(mode));

    public Task<RepeatMode> GetRepeatModeAsync() =>
        Task.Run(() => _player.RepeatMode());

    private void RefreshCurrentTrackFromQueue()
    {
        var position = _player.QueuePosition();
        CurrentTrack = position is uint index && index < _queueTracks.Count
            ? _queueTracks[(int)index]
            : null;
        CurrentTrackChanged?.Invoke();
    }

    private async Task PollForTrackEndAsync()
    {
        var advanced = await Task.Run(() => _player.AdvanceIfFinished());
        if (advanced)
        {
            RefreshCurrentTrackFromQueue();
        }
        else if (CurrentTrack is not null && !await Task.Run(() => _player.HasTrack()))
        {
            // The queue reached its end (repeat is off) — nothing left to play.
            CurrentTrack = null;
            CurrentTrackChanged?.Invoke();
        }
    }
}
