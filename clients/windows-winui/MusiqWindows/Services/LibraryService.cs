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

    /// <summary>The track passed to the most recent <see cref="PlayTrackAsync"/>
    /// call, or <c>null</c> once <see cref="StopAsync"/> has been called.
    /// Raised on the thread that awaited the triggering call — subscribers
    /// touching the UI must already be on the UI thread when this fires,
    /// which holds here since every ViewModel call is awaited from one.</summary>
    public TrackItem? CurrentTrack { get; private set; }

    public event Action? CurrentTrackChanged;

    private LibraryService()
    {
        var localFolder = Windows.Storage.ApplicationData.Current.LocalFolder.Path;
        DatabasePath = Path.Combine(localFolder, "musiq-library.sqlite3");
        _library = Library.Open(DatabasePath);
        _player = new Player();
    }

    public Task<uint> ScanFolderAsync(string folderPath) =>
        Task.Run(() => _library.ScanFolder(folderPath));

    public Task<IReadOnlyList<Track>> ListTracksAsync() =>
        Task.Run(() => (IReadOnlyList<Track>)_library.ListTracks());

    public Task<IReadOnlyList<string>> ListScanRootsAsync() =>
        Task.Run(() => (IReadOnlyList<string>)_library.ListScanRoots());

    public async Task PlayTrackAsync(TrackItem track)
    {
        await Task.Run(() => _player.Play(track.Path));
        CurrentTrack = track;
        CurrentTrackChanged?.Invoke();
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
}
