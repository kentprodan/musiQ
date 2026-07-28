using System.Collections.ObjectModel;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;
using UniffiNavidromeAlbum = uniffi.musiq_uniffi.NavidromeAlbum;
using UniffiNavidromeFolder = uniffi.musiq_uniffi.NavidromeFolder;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.ViewModels;

/// Flat, pre-formatted view of a Plex track for display — kept separate
/// from <see cref="TrackItem"/> since Plex tracks don't support tag editing
/// or renaming, only playback.
internal sealed record PlexTrackDisplay(string Title, string Artist, string Album, string Duration, UniffiPlexTrack Raw)
{
    internal static PlexTrackDisplay From(UniffiPlexTrack track) => new(
        Title: string.IsNullOrWhiteSpace(track.Title) ? "Untitled" : track.Title,
        Artist: track.Artist ?? "Unknown Artist",
        Album: track.Album ?? "Unknown Album",
        Duration: track.DurationSecs is uint secs ? $"{secs / 60}:{secs % 60:D2}" : "--:--",
        Raw: track);
}

/// Same idea as <see cref="PlexTrackDisplay"/>, for a Navidrome/Subsonic song.
internal sealed record NavidromeSongDisplay(string Title, string Artist, string Album, string Duration, UniffiNavidromeSong Raw)
{
    internal static NavidromeSongDisplay From(UniffiNavidromeSong song) => new(
        Title: string.IsNullOrWhiteSpace(song.Title) ? "Untitled" : song.Title,
        Artist: song.Artist ?? "Unknown Artist",
        Album: song.Album ?? "Unknown Album",
        Duration: song.DurationSecs is uint secs ? $"{secs / 60}:{secs % 60:D2}" : "--:--",
        Raw: song);
}

internal partial class SourcesViewModel : ObservableObject
{
    public ObservableCollection<string> ScannedFolders { get; } = new();

    [ObservableProperty]
    private string _statusMessage = "No folders scanned yet — add one from the Library page.";

    [ObservableProperty]
    private string _plexStatusMessage = "Not connected.";

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanConnectToPlex))]
    private bool _isConnectingToPlex;

    public bool CanConnectToPlex => !IsConnectingToPlex;

    [ObservableProperty]
    private bool _isPlexConnected;

    public ObservableCollection<UniffiPlexLibrary> PlexLibraries { get; } = new();

    public ObservableCollection<PlexTrackDisplay> PlexTracks { get; } = new();

    [ObservableProperty]
    private string _navidromeStatusMessage = "Not connected.";

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanConnectToNavidrome))]
    private bool _isConnectingToNavidrome;

    public bool CanConnectToNavidrome => !IsConnectingToNavidrome;

    [ObservableProperty]
    private bool _isNavidromeConnected;

    public ObservableCollection<UniffiNavidromeFolder> NavidromeFolders { get; } = new();

    public ObservableCollection<UniffiNavidromeAlbum> NavidromeAlbums { get; } = new();

    public ObservableCollection<NavidromeSongDisplay> NavidromeSongs { get; } = new();

    public SourcesViewModel()
    {
        _ = RefreshCommand.ExecuteAsync(null);
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        var roots = await LibraryService.Instance.ListScanRootsAsync();

        ScannedFolders.Clear();
        foreach (var root in roots)
        {
            ScannedFolders.Add(root);
        }

        StatusMessage = ScannedFolders.Count == 0
            ? "No folders scanned yet — add one from the Library page."
            : $"{ScannedFolders.Count} folder(s) scanned.";
    }

    public async Task ConnectToPlexAsync(string baseUrl, string token)
    {
        if (string.IsNullOrWhiteSpace(baseUrl) || string.IsNullOrWhiteSpace(token))
        {
            PlexStatusMessage = "Enter both a server URL and a token.";
            return;
        }

        IsConnectingToPlex = true;
        PlexStatusMessage = "Connecting…";
        PlexLibraries.Clear();
        PlexTracks.Clear();

        try
        {
            await PlexService.Instance.ConnectAsync(baseUrl, token);
            var libraries = await PlexService.Instance.ListMusicLibrariesAsync();

            foreach (var library in libraries)
            {
                PlexLibraries.Add(library);
            }

            IsPlexConnected = true;

            if (libraries.Count == 0)
            {
                PlexStatusMessage = "Connected, but no music libraries were found.";
            }
            else
            {
                var plural = libraries.Count == 1 ? "" : "ies";
                var singular = libraries.Count == 1 ? "y" : "";
                PlexStatusMessage = $"Connected — {libraries.Count} music librar{singular}{plural}.";
                await LoadPlexLibraryAsync(libraries[0]);
            }
        }
        catch (MusiqException ex)
        {
            PlexStatusMessage = $"Connection failed: {ex.Message}";
        }
        finally
        {
            IsConnectingToPlex = false;
        }
    }

    [RelayCommand]
    private void DisconnectPlex()
    {
        PlexService.Instance.Disconnect();
        PlexLibraries.Clear();
        PlexTracks.Clear();
        IsPlexConnected = false;
        PlexStatusMessage = "Not connected.";
    }

    public async Task LoadPlexLibraryAsync(UniffiPlexLibrary library)
    {
        PlexStatusMessage = $"Loading \"{library.Title}\"…";
        try
        {
            var tracks = await PlexService.Instance.ListTracksAsync(library.Key);

            PlexTracks.Clear();
            foreach (var track in tracks)
            {
                PlexTracks.Add(PlexTrackDisplay.From(track));
            }

            PlexStatusMessage = $"{library.Title}: {tracks.Count} track(s).";
        }
        catch (MusiqException ex)
        {
            PlexStatusMessage = $"Failed to load library: {ex.Message}";
        }
    }

    public async Task PlayPlexTrackAsync(UniffiPlexTrack track)
    {
        try
        {
            PlexStatusMessage = $"Playing \"{track.Title}\"…";
            var queue = PlexTracks.Select(t => t.Raw).ToList();
            await PlexService.Instance.PlayTrackAsync(track, queue);
        }
        catch (MusiqException ex)
        {
            PlexStatusMessage = $"Playback failed: {ex.Message}";
        }
    }

    public async Task ConnectToNavidromeAsync(string baseUrl, string username, string password)
    {
        if (string.IsNullOrWhiteSpace(baseUrl) || string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            NavidromeStatusMessage = "Enter a server URL, username, and password.";
            return;
        }

        IsConnectingToNavidrome = true;
        NavidromeStatusMessage = "Connecting…";
        NavidromeFolders.Clear();
        NavidromeAlbums.Clear();
        NavidromeSongs.Clear();

        try
        {
            await NavidromeService.Instance.ConnectAsync(baseUrl, username, password);
            var folders = await NavidromeService.Instance.ListMusicFoldersAsync();

            foreach (var folder in folders)
            {
                NavidromeFolders.Add(folder);
            }

            IsNavidromeConnected = true;

            if (folders.Count == 0)
            {
                NavidromeStatusMessage = "Connected, but no music folders were found.";
            }
            else
            {
                NavidromeStatusMessage = $"Connected — {folders.Count} music folder(s).";
                await LoadNavidromeFolderAsync(folders[0]);
            }
        }
        catch (MusiqException ex)
        {
            NavidromeStatusMessage = $"Connection failed: {ex.Message}";
        }
        finally
        {
            IsConnectingToNavidrome = false;
        }
    }

    [RelayCommand]
    private void DisconnectNavidrome()
    {
        NavidromeService.Instance.Disconnect();
        NavidromeFolders.Clear();
        NavidromeAlbums.Clear();
        NavidromeSongs.Clear();
        IsNavidromeConnected = false;
        NavidromeStatusMessage = "Not connected.";
    }

    public async Task LoadNavidromeFolderAsync(UniffiNavidromeFolder folder)
    {
        NavidromeStatusMessage = $"Loading \"{folder.Name}\"…";
        NavidromeSongs.Clear();
        try
        {
            var albums = await NavidromeService.Instance.ListAlbumsAsync(folder.Id);

            NavidromeAlbums.Clear();
            foreach (var album in albums)
            {
                NavidromeAlbums.Add(album);
            }

            NavidromeStatusMessage = $"{folder.Name}: {albums.Count} album(s). Pick one to see its songs.";
        }
        catch (MusiqException ex)
        {
            NavidromeStatusMessage = $"Failed to load folder: {ex.Message}";
        }
    }

    public async Task LoadNavidromeAlbumAsync(UniffiNavidromeAlbum album)
    {
        NavidromeStatusMessage = $"Loading \"{album.Name}\"…";
        try
        {
            var songs = await NavidromeService.Instance.ListSongsAsync(album.Id);

            NavidromeSongs.Clear();
            foreach (var song in songs)
            {
                NavidromeSongs.Add(NavidromeSongDisplay.From(song));
            }

            NavidromeStatusMessage = $"{album.Name}: {songs.Count} song(s).";
        }
        catch (MusiqException ex)
        {
            NavidromeStatusMessage = $"Failed to load album: {ex.Message}";
        }
    }

    public async Task PlayNavidromeSongAsync(UniffiNavidromeSong song)
    {
        try
        {
            NavidromeStatusMessage = $"Playing \"{song.Title}\"…";
            var queue = NavidromeSongs.Select(s => s.Raw).ToList();
            await NavidromeService.Instance.PlayTrackAsync(song, queue);
        }
        catch (MusiqException ex)
        {
            NavidromeStatusMessage = $"Playback failed: {ex.Message}";
        }
    }
}
