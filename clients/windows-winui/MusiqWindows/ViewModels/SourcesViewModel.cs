using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MusiqWindows.Services;
using uniffi.musiq_uniffi;
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

    public ObservableCollection<UniffiPlexLibrary> PlexLibraries { get; } = new();

    public ObservableCollection<PlexTrackDisplay> PlexTracks { get; } = new();

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
            PlexStatusMessage = $"Downloading \"{track.Title}\"…";
            await PlexService.Instance.PlayTrackAsync(track);
            PlexStatusMessage = $"Playing \"{track.Title}\".";
        }
        catch (MusiqException ex)
        {
            PlexStatusMessage = $"Playback failed: {ex.Message}";
        }
    }
}
