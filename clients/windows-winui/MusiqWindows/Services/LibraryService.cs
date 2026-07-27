using uniffi.musiq_uniffi;

namespace MusiqWindows.Services;

/// <summary>
/// Owns the single <see cref="Library"/> handle for the app's lifetime and
/// wraps every call to it in <see cref="Task.Run"/>, since the underlying
/// Rust core does synchronous SQLite/file I/O and must never block the UI
/// thread.
/// </summary>
internal sealed class LibraryService
{
    private static readonly Lazy<LibraryService> LazyInstance = new(() => new LibraryService());

    public static LibraryService Instance => LazyInstance.Value;

    public string DatabasePath { get; }

    private readonly Library _library;

    private LibraryService()
    {
        var localFolder = Windows.Storage.ApplicationData.Current.LocalFolder.Path;
        DatabasePath = Path.Combine(localFolder, "musiq-library.sqlite3");
        _library = Library.Open(DatabasePath);
    }

    public Task<uint> ScanFolderAsync(string folderPath) =>
        Task.Run(() => _library.ScanFolder(folderPath));

    public Task<IReadOnlyList<Track>> ListTracksAsync() =>
        Task.Run(() => (IReadOnlyList<Track>)_library.ListTracks());

    public Task<IReadOnlyList<string>> ListScanRootsAsync() =>
        Task.Run(() => (IReadOnlyList<string>)_library.ListScanRoots());
}
